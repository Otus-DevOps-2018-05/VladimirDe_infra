provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_project_metadata" "infra" {
  project = "${var.project}"

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "google_compute_instance" "app" {
  name         = "${format("reddit-app-%03d", count.index + 1)}"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]
  count        = "${var.count}"

  # metadata {
  #  ssh-keys = <<EOF
  #    appuser1:${chomp(file(var.public_key_path1))}
  #    appuser2:${chomp(file(var.public_key_path2))}
  #    appuser3:${chomp(file(var.public_key_path3))}EOF
  #}

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }
  network_interface {
    network       = "default"
    access_config = {}
  }
  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}
