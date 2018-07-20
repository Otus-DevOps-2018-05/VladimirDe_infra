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

# Практика IaC с использованием Terraform
При использовании IaC есть проблема - больше нельзя вносить изменения в инфраструктуру вручную, т.е. IaC используется или всегда или никогда. Все изменения сделанные вручную "невидимы" для Терраформа.

## Настройка HTTP балансировщика для пары хостов reddit-app, reddit-app2
После добавления reddit-app2 и настройки http балансировщика через terraform есть проблема, которая заключается в том, что приложение reddit-app это statefull приложение, т.е. у него есть состояние (мы храним его в mongodb), которое балансировка не учитывает. В этом легко убедиться, если создать статью и сравнить БД на reddit-app и reddit-app2:

```bash
reddit-app:~# mongo
MongoDB shell version: 3.2.20
connecting to: test
> show dbs
local  0.000GB``
>

reddit-app2:~# mongo
MongoDB shell version: 3.2.20
connecting to: test
> show dbs
local       0.000GB
user_posts  0.000GB
>
```bash

т.е. пользователь будет получать разный ответ в зависимости от того, на какой бэкенд он попал. Решения:

- убрать mongodb с app серверов и перевести его на отдельный сервер БД
- включить репликацию между серверами mongo.
Количество app серверов настраивается переменной count (по-умолчанию она равна 1) в файле terraform.tfvars Например, если задать
count = 4 то будет создано 4 инстанса reddit-app-001, reddit-app-002, reddit-app-003б reddit-app-004

При этом после выполнения команды

terraform apply будут выведены ip адреса каждого инстанса и ip адрес loadbalancer

app_external_ip = [ reddit-app-001-ip-address-here, reddit-app-002-ip-address-here, reddit-app-003-ip-address-here reddit-app-004-ip-address-here
] lb_app_external_ip = loadbalancer-ip-address-here

# ДЗ 8 Terraform-2
## Как запустить проект
Исходное состояние: установлены terraform (проверено на версии v0.11.7), packer (проверено на версии 1.2.4) с доступом к GCP

Создать образы reddit-app, reddit-db через packer, предварительно настроив variables.json

```bash
cd packer
cp variables.json{.example,}
#configure variables.json here
packer build -var-file=variables.json db.json
packer build -var-file=variables.json app.json
```bash

cd -
Создать бакеты для хранения state файла terraform, предварительно настроив terraform.tfvars

```bash
cd terraform
cp terraform.tfvars{.example,}
#configure terraform.tfvars here
terraform init
terraform apply -auto-approve
```bash

Создать prod/stage окружение, например для stage выполнить (при этом, для prod нужно задать переменную source_ranges для доступа по ssh):

```bash
cd stage/
cp terraform.tfvars{.example,}
#configure terraform.tfvars here
terraform init
terraform apply -auto-approve
```bash

## 7.3 Как проверить
В terraform/stage (или terraform/prod) выполнить
```bash
terraform output
```bash
будут выведены переменные app_external_ip, db_external_ip, при этом по адресу http://app_external_ip:9292 будет доступно приложение.
