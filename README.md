# Vladimir Denisov infra

**Build status**

master:
[![Build Status](https://travis-ci.com/Otus-DevOps-2018-05/VladimirDe_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-05/VladmirDe_infra)

ansible-4:
[![Build Status](https://travis-ci.com/Otus-DevOps-2018-05/VladimirDe_infra.svg?branch=ansible-4)](https://travis-ci.com/Otus-DevOps-2018-05/VladimirDe_infra)

db role:
[![Build Status](https://travis-ci.org/Vladimir/ansible-role-mongodb.svg?branch=master)](https://travis-ci.org/VladmirDe/ansible-role-mongodb)

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
```
$ host  someinternalhost
someinternalhost.c.infra-208603.internal has address 10.132.0.2
```
### Для ssh версии 7.3 и выше
В новых версиях ssh для этих целей существует опция **ProxyJump** (ключ -J)
```
ssh -V
OpenSSH_7.6p1 Ubuntu-4, OpenSSL 1.0.2n  7 Dec 2017
```
Пример подключения из командной строки
```
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
```
ssh  -o 'ProxyCommand ssh appuser@35.206.144.27 -W %h:%p' appuser@someinternalhost
```
### Настройка ~/.ssh/config
Чтобы каждый раз при подключении к **someinternalhost** не указывать параметры **bastion** хоста, можно модифицировать **~/.ssh/config**
```
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
```
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

```
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
```

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

```
cd packer
cp variables.json{.example,}
#configure variables.json here
packer build -var-file=variables.json db.json
packer build -var-file=variables.json app.json
```

cd -
Создать бакеты для хранения state файла terraform, предварительно настроив terraform.tfvars

```
cd terraform
cp terraform.tfvars{.example,}
#configure terraform.tfvars here
terraform init
terraform apply -auto-approve
```

Создать prod/stage окружение, например для stage выполнить (при этом, для prod нужно задать переменную source_ranges для доступа по ssh):

```
cd stage/
cp terraform.tfvars{.example,}
#configure terraform.tfvars here
terraform init
terraform apply -auto-approve
```
## 7.3 Как проверить
В terraform/stage (или terraform/prod) выполнить
```
terraform output
```
будут выведены переменные app_external_ip, db_external_ip, при этом по адресу http://app_external_ip:9292 будет доступно приложение.


## 10.3 Как проверить проект
В README.md должен стоять бэйдж build passing

В terraform/stage (или terraform/prod) выполнить
```
terraform output
```
будут выведены переменные app_external_ip, db_external_ip, при этом по адресу http://app_external_ip будет доступно приложение


# Homework-11: Разработка и тестирование Ansible ролей и плейбуков
## 11.1 Что было сделано
Основные задания:

Локальная разработка при помощи Vagrant - в Vagrantfile описаны конфигурации appserver, dbserver

Добавлен плейбук base.yml для ansible bootstrap на хостах, где не установлен python

Доработана роль db для использования в Vagrant, в которую добавлены таски config_mongo.yml, install_mongo.yml

В Vagrantfile добавлены ansible провижинеры для appserver и dbserver

Добавлены тесты роли db через molecula и testinfra

## Задания со *:

Добавлено dev окружение, в котором настроена параметризация конфигурации appserver в Vagrant

Роль db перемещена в отдельный репозиторий VladimirDe/ansible-role-mongodb, роль db импортирована в ansible galaxy и подключена через файл зависимостей requirements.yml для stage и prod окружений

Для роли db настроен запуск тестов molecule/testinfra в GCE через travis ci после пуша в репозиторий, в README.md роли добавлен бэйдж статуса сборки, включена интеграция билдов travis ci со slack каналом интеграции

## 11.2 Как запустить проект
### 11.2.1 Репозиторий ansible роли db
Запуск тестов вручную без travis

Склонировать репозиторий
```
git clone git@github.com:VladimirDe/ansible-role-mongodb.git
cd ansible-role-mongodb
```
Предполагается, что ssh ключи для подключения к инстансам GCE лежат в ~/.ssh/google_compute_engine{,pub}
ssh-keygen -t rsa -f google_compute_engine -C 'travis' -q -N ''
Как загрузить ключи в GCP описано здесь https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys

Генерируем сервисный аккаунт
```
gcloud iam service-accounts create travis --display-name travis
```
Создаем файл с секретной информацией для подключения сервисного аккаунта
```
gcloud iam service-accounts keys create ./credentials.json --iam-account travis@infra-208603.iam.gserviceaccount.com
```
Добавляем роли для сервисного аккаунта
```
gcloud projects add-iam-policy-binding infra-208603 --member serviceAccount:travis@infra-208603.iam.gserviceaccount.com --role roles/editor
```
Примечание1: здесь указана роль roles/editor у которой достаточно много полномочий, возможно стоит указать роль с меньшими полномочиями

Запуск тестов molecule в GCE (нужно заменить infra-some-project-id на реальный проект)
```
export P_ID=infra-some-project-id
USER=travis GCE_SERVICE_ACCOUNT_EMAIL=travis@${P_ID}.iam.gserviceaccount.com GCE_CREDENTIALS_FILE=$(pwd)/credentials.json GCE_PROJECT_ID=${P_ID} molecule test
```
Настройка интеграции с travis ci (ВАЖНО!!!: если для проверок используется временный репозиторий (в примерах это trytravis-db-role), то нужно везде указывать имя репозитория при шифровании секретных данных, также нужно временно сменить имя роли на trytravis-db-role в molecule playbook)
```
travis encrypt 'GCE_SERVICE_ACCOUNT_EMAIL=travis@infra-208603.iam.gserviceaccount.com' --repo VladimirDe/ansible-role-mongodb
travis encrypt GCE_CREDENTIALS_FILE=\$TRAVIS_BUILD_DIR/credentials.json --repo VladimirDe/ansible-role-mongodb
travis encrypt 'GCE_PROJECT_ID=infra-208603' --repo VladimirDe/ansible-role-mongodb
travis login --org --repo VladimirDe/ansible-role-mongodb
tar cvf secrets.tar credentials.json google_compute_engine
travis encrypt-file secrets.tar --repo VladimirDe/ansible-role-mongodb --add
```
Проверить и поправить файл .travis.yml - после автоматического добавления шифрованных данных через travis encrypt линтер начинает выдавать ошибки
```
molecule lint
```
После того, как все ошибки будут исправлены через trytravis, нужно перешифровать все данные, но уже для основного репозитория (повторить предыдущие шаги, но без ключа --repo)

Интеграция со slack каналом
```
travis encrypt "devops-team-otus:some-secret-info" --add notifications.slack -r VladimirDe/ansible-role-mongodb
molecule lint
```
Если нужно, то поправить .travis.yml
### 11.2.2 Интеграция роли db с ansible galaxy
Зарегистрироваться на ansible galaxy

Настроить метаданные роли (author, description, license, tags, platforms, company) в meta/main.yml
```
---
dependencies: []
galaxy_info:
  author: VladimirDe
  description: mongo database for Ubuntu Xenial
  company: Gotechsoftware
  license: MIT
  min_ansible_version: 2.4
  platforms:
    - name: Ubuntu
      versions:
        - xenial
  galaxy_tags:
    - mongo
```
Импортировать роль в ansible galaxy, используя web-интерфейс Ansible galaxy

## 11.2.3 Запуск dev окружения
Запустить проект в dev окружении (appserver, dbserver)
```
cd ansible
ansible-galaxy install -r environments/dev/requirements.yml
vagrant up
```
Удалить dev окружение
```
vagrant destroy
```
## 11.3 Как проверить проект
appserver, dbserver должны быть доступны по ssh
```
vagrant ssh appserver
vagrant ssh dbserver
```
В браузере должно открываться reddit приложение по адресу http://10.10.10.20/


# Homework-9: Деплой и управление конфигурацией с Ansible
## 9.1 Что было сделано
Основные задания:

- Создание плейбуков ansible для конфигурирования и деплоя reddit приложения (site.yml, db.yml, app.yml, deploy.yml)
- Создание плейбуков ansible (packer_db.yml, packer_app.yml), их использование в packer
- Задания со *:

## Исследование возможности использования dynamic inventory в GCP через contrib модуль ansible (gce.py) и terraform state file
Настройка dynamic inventory (выбран и используется gce.py). Дополнительно написаны ansible плейбуки для конфигурирования dynamic inventory (terraform_dynamic_inventory_setup.yml, gce_dynamic_inventory_setup.yml)
## 9.2 Как запустить проект
Предварительные действия: развернуть stage (см. 7.2 Как запустить проект)

### 9.2.1 Настройка динамического inventory через gce.py (основной способ, используется в плейбуках раздела 9.2.3)
Преимущества: поставляется вместе с ansible; проще в настройке

Недостатки: это inventory только для GCE

Нужно создать сервисный аккаунт в GCE, скачать credential file в формате json и указать к нему путь во время исполнения gce_dynamic_inventory_setup.yml

cd ansible
ansible-playbook gce_dynamic_inventory_setup.yml
Enter path to GCE service account pem file [credentials/gce-service-account.json]:
Посмотреть хосты динамического inventory через gce.py можно так:
```bash
sudo apt-get install jq
./inventory_gce/gce.py --list | jq .
```
### 9.2.2 Настройка динамического inventory через terraform-inventory
Не удалось
Сообщение об ошибке при компиляции:
```bash
TASK [Compile terraform inventory binary file] *****************************************************************************************************************************
fatal: [localhost]: FAILED! => {"changed": true, "cmd": ["bin/dist", "master"], "delta": "0:00:00.635740", "end": "2018-07-29 08:41:29.544858", "msg": "non-zero return code", "rc": 127, "start": "2018-07-29 08:41:28.909118", "stderr": "bin/dist: line 26: zip: command not found", "stderr_lines": ["bin/dist: line 26: zip: command not found"], "stdout": "/tmp/terraform-inventory/pkg /tmp/terraform-inventory", "stdout_lines": ["/tmp/terraform-inventory/pkg /tmp/terraform-inventory"]}
```
Компилировалось на WSL - возможно это корень проблемы (не нативная Unix)


### 9.2.3 Конфигурация и деплой приложения
Выполняем 9.2.1 Настройка динамического inventory через gce.py

cd ansible
ansible-playbook site.yml
## 9.3 Как проверить проект
Описано в 7.3 Как проверить

# Homework-8: Управление конфигурацией. Основные DevOps инструменты. Знакомство с Ansible
## 8.1 Что было сделано
### Основные задания:

- Установка и знакомство с базовыми функциями ansible
- Написание простых плейбуков
- Задания со *: Создание inventory в формате json

## 8.2 Как запустить проект
Развернуть stage через terraform (см. 7.2 Как запустить проект), после чего перейти в каталог ansible и запустить плейбук, клонирующий репозиторий reddit на app сервер

```
cd ansible
ansible-playbook clone.yml
```
Повторный запуск плейбука идемпотентен, т.е. повторно клонироваться репозиторий не будет (changed=0)

ansible-playbook clone.yml
...
appserver                  : ok=2    changed=0    unreachable=0    failed=0
Но если удалить склонированный репозиторий

ansible app -m command -a 'rm -rf ~/reddit'
 [WARNING]: Consider using file module with state=absent rather than running rm

appserver | SUCCESS | rc=0 >>
то исполнение плейбука склонирует репозиторий заново (changed=1)

ansible-playbook clone.yml
...
appserver                  : ok=2    changed=1    unreachable=0    failed=0
Для запуска ansible с использованием inventory в формате json нужен инвентори-скрипт, который в самом простом случае при вызове с ключом --list должен выводить хосты в json формате. Например, если у нас уже есть inventory.json, то передать его ansible можно таким скриптом inventory_json
```bash
#!/usr/bin/env bash

if [ "$1" = "--list" ] ; then
    cat $(dirname "$0")/inventory.json
elif [ "$1" = "--host" ]; then
    echo "{}"
fi
```

```
ansible -i inventory_json all -m ping
```
Чтобы не указывать inventory_json, его можно добавить в ansible.cfg
```

```
ansible -i inventory_json all -m ping
```
Чтобы не указывать inventory_json, его можно добавить в ansible.cfg
```
inventory =./inventory_json
```

## 8.3 Как проверить
После выполнения плейбука clone.yml можно проверить, что репозиторий действительно склонировался, например командой

```
ansible appserver -m command  -a "git log -1 chdir=/home/appuser/reddit"
```

