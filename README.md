# Vladimir Denisov infra


## Подключение через ssh к инстансам в GCP через bastion хост
### Начальные данные
* bastion
 * Пользователь: appuser
 * External IP: 35.234.130.53
 * Internal IP: 10.154.0.2
* someinternalhost
  * Пользователь: appuser
  * Internal IP: 10.132.0.2

На **bastion** имя **someinternalhost** разрешается в IP адрес
```bash
$ host  someinternalhost
someinternalhost.c.infra-208603.internal has address 10.132.0.2
```
### Для ssh версии 7.3 и выше
В новых версиях ssh для этих целей существует опция **ProxyJump** (ключ -J)
```bash
ssh -V
OpenSSH_7.6p1 Ubuntu-4, OpenSSL 1.0.2n  7 Dec 2017
```
Пример подключения из командной строки
```bash
$ ssh -i ~/.ssh/appuser -J appuser@35.234.130.53 appuser@someinternalhost
Welcome to Ubuntu 16.04.4 LTS (GNU/Linux 4.13.0-1019-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.


Last login: Fri Jun 29 03:35:18 2018 from 10.154.0.2
appuser@someinternalhost:~$
```

### Для ssh более старых версий
В старых версиях ssh опции **ProxyJump** нет, но можно использовать опцию **ProxyCommand** и команда для подключения к **someinternalhost** будет выглядеть так:
```bash
ssh  -o 'ProxyCommand ssh appuser@35.206.144.27 -W %h:%p' appuser@someinternalhost
```
### Настройка ~/.ssh/config
Чтобы каждый раз при подключении к **someinternalhost** не указывать параметры **bastion** хоста, можно модифицировать **~/.ssh/config**
```bash
$ if ssh -J 2>&1 | grep "unknown option -- J" >/dev/null; then PROXY_COMMAND='ProxyCommand ssh appuser@bastion -W %h:%p'; else PROXY_COMMAND='ProxyJump %r@bastion'; fi
$ cat <<EOF>>~/.ssh/config

host bastion
HostName 35.234.130.53

host someinternalhost
  HostName someinternalhost
  User appuser
  ServerAliveInterval 30
${PROXY_COMMAND}
  IdentityFile ~/.ssh/appuser
EOF

```
### Проверка подключения через alias **someinternalhost**
```bash
$ ssh someinternalhost
Welcome to Ubuntu 16.04.4 LTS (GNU/Linux 4.13.0-1019-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.


Last login: Fri Jun 29 03:35:37 2018 from 10.154.0.2
appuser@someinternalhost:~$
```
## Подключение к инстансам в GCP через VPN

На **bastion** установлен и настроен pritunl VPN сервер. Для подключения к VPN нужно импортировать конфигурационный файл **cloud-bastion.ovpn** в OpenVPN клиент.

bastion_IP = 35.234.130.53
someinternalhost_IP = 10.132.0.2

# ДЗ №4

testapp_IP = 35.233.15.239
testapp_port = 9292

Команда для добавления правила файрволла: gcloud compute firewall-rules create puma-default-server --target-tags="puma-server" --source-ranges="0.0.0.0/0" --allow tcp:9292

Команда для запуска со startup-скриптом:

'<gcloud compute instances create reddit-app-2\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup.sh>'
  
Сборка образов VM при помощи packer
Чтобы собрать образ VM нужно переименовать файл packer/variables.json.example и настроить в нем переменные gcp_project_id, gcp_source_image_family

'<mv packer/variables.json{.example,}>'
После этого образ reddit-base можно собрать командами

'<cd packer && packer validate -var-file=variables.json ubuntu16.json && packer build -var-file=variables.json  ubuntu16.json>'
и аналогично reddit-full

'<cd packer && packer validate -var-file=variables.json immutable.json && packer build -var-file=variables.json  immutable.json>'
после этого, создать и запустить инстанс можно скриптом create-reddit-vm.sh (по-умолчанию используется образ reddit-full)

config-scripts/create-reddit-vm.sh
чтобы использовать другой образ его нужно указать через ключ командной строки, например -i reddit-base

'<config-scripts/create-reddit-vm.sh -i reddit-base
...
config-scripts/create-reddit-vm.sh -h
Usage: create-reddit-vm.sh [-n INSTANCE_NAME] [-i IMAGE_FAMILY]>'
