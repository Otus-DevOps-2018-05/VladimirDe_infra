tf_inventory
=========

Роль для настройки dynamic inventory в ansible через terraform state file

Requirements
------------

- Предполагается, что структура каталогов ansible выглядит так

```bash
├── environments
│   ├── prod
│   │   └── group_vars
│   └── stage
│       └── group_vars
├── playbooks
└── roles
└── ansible.cfg
```

- Предполагается, что ansible.cfg расположен в корне репозитория ansible

Role Variables
--------------

- tf_inventory_ansible_path - путь к репозиторию ansible в котором нужно настроить dynamic inventory

- tf_inventory_env - окружение (имя подкаталога в environments). Например, prod

Dependencies
------------

Нет

Example Playbook
----------------

```yaml
    - hosts: localhost
      connection: local
      roles:
      - role: tf_inventory
        tf_inventory_ansible_path: /home/user/ansible
        tf_inventory_env: prod
```

License
-------

BSD

Author Information
------------------
