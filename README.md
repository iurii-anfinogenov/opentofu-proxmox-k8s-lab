# OpenTofu Proxmox Kubernetes Lab

Infrastructure-as-Code проект для развёртывания Kubernetes нод на Proxmox с помощью OpenTofu.

Проект демонстрирует безопасное управление кластером: удаление или добавление одной ноды не приводит к пересозданию остальных.

# Архитектура

Проект состоит из корневой конфигурации и модуля для создания VM.

```text
.
├── main.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── outputs.tf
└── modules/
    └── k8s-node/
        ├── main.tf
        ├── locals.tf
        ├── variables.tf
        └── outputs.tf
```

Корневая конфигурация описывает параметры кластера и список нод.
Модуль `k8s-node` отвечает за создание виртуальных машин в Proxmox.

# Основная идея

Каждая нода имеет фиксированный `index`.

Этот индекс используется для расчёта:

* hostname
* VMID
* IP-адреса

Пример:

```text
hostname = prefix-role-index
vmid     = vmid_start + index
ip       = cluster_ip_start + ip_offset + index
```

Это гарантирует, что удаление одной ноды не изменяет параметры остальных.

# Конфигурация нод

Ноды задаются в `locals.tf`.

Пример:

```hcl
locals {
  nodes = {
    master1 = {
      role      = "master"
      index     = 1
      cpu       = 2
      memory    = 4096
      disk      = 20
      datastore = "local-lvm"
      ip_offset = 0
    }

    master3 = {
      role      = "master"
      index     = 3
      cpu       = 2
      memory    = 4096
      disk      = 20
      datastore = "local-lvm"
      ip_offset = 0
    }

    worker1 = {
      role      = "worker"
      index     = 1
      cpu       = 2
      memory    = 4096
      disk      = 20
      datastore = "local-lvm"
      ip_offset = 5
    }
  }
}
```

# Развёртывание

Инициализация:

```bash
tofu init
```

Проверка конфигурации:

```bash
tofu validate
```

Просмотр плана:

```bash
tofu plan
```

Применение:

```bash
tofu apply
```

# Изменение состава кластера

Чтобы удалить ноду, достаточно убрать её из `locals.tf`.

Пример: если удалить `master2`, остальные ноды не изменят:

* hostname
* VMID
* IP-адрес

Это достигается за счёт фиксированного `index` для каждой ноды.

# Важно

`index` должен быть уникальным внутри своей роли и оставаться постоянным.

Пример:

* `master1` -> `index = 1`
* `master2` -> `index = 2`
* `master3` -> `index = 3`

Если `master2` удалён, `master3` должен остаться с `index = 3`, а не стать `2`.

# Требования

* OpenTofu
* доступ к Proxmox API
* cloud image Ubuntu
* SSH public key

# Примечание

Проект ориентирован на учебный и лабораторный сценарий.
Для production-среды стоит дополнительно пересмотреть:

* TLS verification в provider
* обработку IP в outputs
* хранение секретов
* state backend
