# OpenTofu + Proxmox 9.1.7 + Ubuntu Cloud-Init

---

## Обучение

Если хотите разобраться глубже, как это всё работает:

- Курс по OpenTofu / Terraform:  
  https://stepik.org/a/238385

---

## Контакты

Автор: Iurii  
Telegram: https://t.me/uanfinogenov
Подробное описание проекта для создания и управления виртуальными машинами в Proxmox через OpenTofu.


Этот вариант документации рассчитан на структуру, где используется одна рабочая директория `cluster/` и один общий модуль `modules/node`.

Документ описывает:

* установку OpenTofu
* оффлайн установку провайдеров
* настройку `~/.tofurc`
* подготовку Ubuntu cloud image / template в Proxmox
* настройку доступа к Proxmox API
* структуру проекта
* работу `cloud-init`
* fallback логику `default.yml`
* использование разных `cloud-init` файлов для разных VM
* работу VLAN
* практические замечания по отладке

---

## Совместимость

Проверено в окружении:

* Proxmox VE 9.1.7
* Ubuntu cloud image (noble / 24.04)
* OpenTofu

Если в вашей среде используются другие версии Proxmox, Ubuntu image или провайдеров, поведение может отличаться.

---
## Важно:
 - перед использованием необходимо проверить и при необходимости изменить переменные под свою среду
 - чаще всего отличаются:
   - datastore (local, local-lvm, ssd и т.д.)
   - image_datastore и путь к образу
   - сетевой bridge (например vmbr0)
   - network_base и gateway
   - VLAN (если используется)
 - значения в примере не универсальны и зависят от конкретного Proxmox окружения

---
## Идея проекта

OpenTofu отвечает за инфраструктуру:

* создание VM
* сеть
* диски
* cloud-init disk
* загрузку cloud-init user-data в Proxmox

Cloud-init отвечает за конфигурацию ОС внутри VM:

* пользователи
* SSH ключи
* hostname
* пакеты
* systemd сервисы
* базовая bootstrap-настройка

Это ключевой принцип проекта:

* OpenTofu не должен подробно конфигурировать ОС
* cloud-init не должен управлять инфраструктурой Proxmox

---

## Структура проекта

Ожидаемая структура:

```text
.
├── README.md
├── terraform.tfvars.example
├── cluster/
│   ├── cloud-config/
│   │   └── default.yml
│   ├── locals.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars
│   └── variables.tf
└── modules/
    └── node/
        ├── cloud-config/
        │   └── default.yml
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

Где:

* `cluster/` - рабочее окружение
* `cluster/cloud-config/` - project-specific cloud-init файлы
* `modules/node/` - общий модуль для VM
* `modules/node/cloud-config/default.yml` - модульный fallback cloud-init
* `terraform.tfvars.example` - пример переменных без секретов

---

## Как работает cloud-init в этом проекте

Для каждой VM модуль выбирает cloud-init файл по следующему правилу:

1. если у ноды задан параметр `cloudinit`, модуль ищет файл в `cluster/cloud-config/<имя файла>`
2. если параметр `cloudinit` не задан, модуль пытается использовать `cluster/cloud-config/default.yml`
3. если файла в `cluster/cloud-config/` нет, используется fallback из модуля: `modules/node/cloud-config/default.yml`

Это даёт три уровня конфигурации:

* per-VM cloud-init
* project default cloud-init
* module fallback cloud-init

---

## Пример логики выбора cloud-init

Пример в `locals.tf`:

```hcl
locals {
  nodes = {
    worker-1 = {
      index     = 1
      cpu       = 2
      memory    = 2048
      disk      = 20
      datastore = "ssd2"
      ip        = "192.168.20.101"
      cloudinit = "worker.yml"
    }

    worker-2 = {
      index     = 2
      cpu       = 2
      memory    = 2048
      disk      = 20
      datastore = "ssd2"
      ip        = "192.168.20.102"
      cloudinit = "worker.yml"
    }

    master-1 = {
      index     = 3
      cpu       = 4
      memory    = 4096
      disk      = 40
      datastore = "ssd2"
      ip        = "192.168.20.110"
      cloudinit = "master.yml"
    }
# ip:
# - опциональный параметр
# - если НЕ задан → вычисляется автоматически
# - формула:
#     ${network_base}.${cluster_ip_start + index}
    test = {
      index     = 5
      cpu       = 1
      memory    = 1024
      disk      = 10
      datastore = "ssd2"
      # ip        = "192.168.20.130" -> ip не задан, вычисляется автоматически
      # cloudinit не задан -> будет использован default.yml
    }
  }
}
```

Поведение:

* `worker-1`, `worker-2` -> `cluster/cloud-config/worker.yml`
* `master-1` -> `cluster/cloud-config/master.yml`
* `test` -> `cluster/cloud-config/default.yml`, а если его нет -> `modules/node/cloud-config/default.yml`

---

## Установка OpenTofu

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://get.opentofu.org/opentofu.gpg \
  | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null

curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
  | sudo gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null

sudo chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg

echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] \
https://packages.opentofu.org/opentofu/tofu/any/ any main" \
  | sudo tee /etc/apt/sources.list.d/opentofu.list >/dev/null

sudo apt-get update
sudo apt-get install -y tofu
```

Проверка:

```bash
tofu version
```

---

## Установка Golang

Для части оффлайн-провайдеров требуется Go.

Установите Golang удобным для вас способом.

Проверка:

```bash
go version
```

---

## Настройка оффлайн-провайдеров

Если OpenTofu должен работать без выхода в интернет, провайдеры нужно положить в локальное зеркало:

```text
~/.terraform.d/plugins/
```

Создание каталогов:

```bash
mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/bpg/proxmox
mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/hashicorp/{local,random,tls}
```

Ожидаемая структура:

```text
/home/user/.terraform.d/
└── plugins
    └── registry.opentofu.org
        ├── bpg
        │   └── proxmox
        │       ├── 0.101.1
        │       │   └── linux_amd64
        │       │       └── terraform-provider-proxmox_v0.101.1
        │       ├── 0.86.0
        │       │   └── linux_amd64
        │       │       └── terraform-provider-proxmox_v0.86.0
        │       └── 0.87.0
        │           └── linux_amd64
        │               └── terraform-provider-proxmox_v0.87.0
        └── hashicorp
            ├── local
            │   └── 2.6.1
            │       └── linux_amd64
            │           └── terraform-provider-local_v2.6.1
            ├── random
            │   └── 3.7.2
            │       └── linux_amd64
            │           └── terraform-provider-random_v3.7.2
            └── tls
                └── 4.1.0
                    └── linux_amd64
                        └── terraform-provider-tls_v4.1.0
```

### Провайдер bpg/proxmox

Релизы:

```text
https://github.com/bpg/terraform-provider-proxmox/releases
```

Пример для версии `0.86.0`:

```bash
wget https://github.com/bpg/terraform-provider-proxmox/releases/download/v0.86.0/terraform-provider-proxmox_0.86.0_linux_amd64.zip
mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/bpg/proxmox/0.86.0/linux_amd64
unzip terraform-provider-proxmox_0.86.0_linux_amd64.zip -d /tmp
mv /tmp/terraform-provider-proxmox_v0.86.0 \
  ~/.terraform.d/plugins/registry.opentofu.org/bpg/proxmox/0.86.0/linux_amd64/
chmod +x ~/.terraform.d/plugins/registry.opentofu.org/bpg/proxmox/0.86.0/linux_amd64/terraform-provider-proxmox_v0.86.0
```

Пояснение:

* `bpg/proxmox` распространяется как готовый бинарник
* его не нужно собирать через `go build`
* достаточно скачать ZIP, распаковать и положить бинарник в локальное зеркало

### Провайдер hashicorp/local

```bash
wget https://github.com/hashicorp/terraform-provider-local/archive/refs/tags/v2.6.1.zip
unzip v2.6.1.zip
cd terraform-provider-local-2.6.1/
go build -o terraform-provider-local .
mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/hashicorp/local/2.6.1/linux_amd64
mv terraform-provider-local \
  ~/.terraform.d/plugins/registry.opentofu.org/hashicorp/local/2.6.1/linux_amd64/terraform-provider-local_v2.6.1
```

### Провайдер hashicorp/random

```bash
wget https://github.com/hashicorp/terraform-provider-random/archive/refs/tags/v3.7.2.zip
unzip v3.7.2.zip
cd terraform-provider-random-3.7.2/
go build -o terraform-provider-random .
mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/hashicorp/random/3.7.2/linux_amd64
mv terraform-provider-random \
  ~/.terraform.d/plugins/registry.opentofu.org/hashicorp/random/3.7.2/linux_amd64/terraform-provider-random_v3.7.2
```

### Провайдер hashicorp/tls

```bash
wget https://github.com/hashicorp/terraform-provider-tls/archive/refs/tags/v4.1.0.zip
unzip v4.1.0.zip
cd terraform-provider-tls-4.1.0/
go build -o terraform-provider-tls .
mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/hashicorp/tls/4.1.0/linux_amd64
mv terraform-provider-tls \
  ~/.terraform.d/plugins/registry.opentofu.org/hashicorp/tls/4.1.0/linux_amd64/terraform-provider-tls_v4.1.0
```

---

## Настройка `~/.tofurc`

Файл `~/.tofurc` говорит OpenTofu использовать только локальные провайдеры и не пытаться скачивать их из интернета.

Пример:

```hcl
provider_installation {
  filesystem_mirror {
    path = "/home/$USER/.terraform.d/plugins"
    include = [
      "registry.opentofu.org/bpg/proxmox",
      "registry.opentofu.org/hashicorp/local",
      "registry.opentofu.org/hashicorp/random",
      "registry.opentofu.org/hashicorp/tls"
    ]
  }

  direct {
    exclude = [
      "registry.opentofu.org/bpg/proxmox",
      "registry.opentofu.org/hashicorp/local",
      "registry.opentofu.org/hashicorp/random",
      "registry.opentofu.org/hashicorp/tls"
    ]
  }
}
```

Проверка:

```bash
tofu init -reconfigure
```

Ожидаемое поведение:

* OpenTofu берёт провайдеры из local filesystem mirror
* в интернет за ними не выходит

---

## Доступ к Proxmox API

Минимальные права для API token:

* `Datastore.AllocateSpace`
* `VM.Allocate`
* `VM.Audit`
* `VM.Config.*`

Пример отдельного файла с credentials:

```bash
vim ~/.pve-creds
```

```bash
export PVE_TOKEN_ID="root@pam!tofu"
export PVE_TOKEN_SECRET="YOUR_SECRET"
export PVE_HOST="192.168.22.5"
```

Загрузка в shell:

```bash
set -a
source ~/.pve-creds
set +a
```

Проверка:

```bash
curl -k -H "Authorization: PVEAPIToken=${PVE_TOKEN_ID}=${PVE_TOKEN_SECRET}" \
  https://$PVE_HOST:8006/api2/json/version
```
В example также показано как можно хранить ключи в файле. Если будете использовать, не забудьте убедится, что файл с переменными в .gitignore.
---

## Подготовка Ubuntu Cloud-Init template в Proxmox

Нужен именно cloud image и корректно подготовленный template.

### Скачать cloud image

```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img -O ubuntu.img
```

### Создать VM под template

```bash
qm create 9001 --name ubuntu-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9001 ubuntu.img local-lvm
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0
qm set 9001 --ide2 local-lvm:cloudinit
qm set 9001 --boot c --bootdisk scsi0
qm set 9001 --serial0 socket --vga serial0
```

### Превратить VM в template

```bash
qm template 9001
```

Важно:

* нужен cloud image
* нужен cloud-init disk
* template должен быть корректно подготовлен

Если этого нет, cloud-init может не применяться внутри VM.

---

## Переменные проекта

Пример `terraform.tfvars.example`:

```hcl
# Proxmox API endpoint (формат: https://host:port/api2/json)
proxmox_endpoint = "https://<IP>:<PORT>/api2/json"

# ID API token (формат: user@realm!token_name)
proxmox_token_id = "terraform@ve!user"

# Secret API token
proxmox_token_secret = "<PROXMOX_TOKEN>"

# Стартовый VMID
worker_vmid_start = 1000

# Дефолтные ресурсы worker VM
worker_cpu = 2
worker_memory = 2048
worker_disk = 20
worker_datastore = "ssd2"

# Datastore, где лежит cloud image
image_datastore = "local"

# Путь к образу
image_file = "import/ubuntu-24.qcow2"

# Сеть
cluster_gateway = "192.168.20.1"
network_base = "192.168.20"
network_cidr = "24"
cluster_ip_start = 0

# Datastore для дополнительных дисков
data_datastore = "data1"
```

Практика:

* реальный `terraform.tfvars` не коммитить
* в git хранить только `terraform.tfvars.example`

---

## Пример описания `nodes`

```hcl
# nodes — описание виртуальных машин
#
# vlan_id:
# - опциональный параметр
# - если НЕ указан → VM будет в обычной сети (untagged, vmbr0)
# - если указан → VM попадет в соответствующий VLAN
#
# cloudinit:
# - опциональный параметр
# - указывает имя cloud-init файла для конкретной VM
# - файл должен находиться в cluster/cloud-config/<имя>.yml
# - если НЕ указан → используется default.yml
# - если файл НЕ найден в cluster/cloud-config → используется fallback из модуля

variable "nodes" {
  type = map(object({
    index     = number
    cpu       = number
    memory    = number
    disk      = number
    datastore = string
    ip_offset = optional(number)
    ip        = optional(string)
    vmid      = optional(number)
    vlan_id   = optional(number)
    data_disk = optional(number)
    cloudinit = optional(string)
  }))
}
```

---

## VLAN

Параметр:

```hcl
vlan_id = 20
```

Поведение:

* если `vlan_id` не указан -> обычная сеть без тегирования
* если `vlan_id` указан -> VM подключается в соответствующий VLAN

Пример:

```hcl
nodes = {
  worker-1 = {
    index     = 1
    cpu       = 2
    memory    = 2048
    disk      = 20
    datastore = "ssd2"
    ip        = "192.168.20.101"
    vlan_id   = 20
    cloudinit = "worker.yml"
  }
}
```

---

## Модульный `default.yml`

Модульный `default.yml` нужен как безопасный fallback, если проект не передал отдельный cloud-init файл.

Пример содержимого:

```yaml
#cloud-config

timezone: Europe/Moscow

users:
  - default
  - name: ubuntu
    groups: [sudo]
    shell: /bin/bash
    lock_passwd: true
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_key}

ssh_pwauth: false

package_update: true

packages:
  - qemu-guest-agent

write_files:
  - path: /etc/motd
    content: |
      Managed by OpenTofu

runcmd:
  - systemctl enable --now qemu-guest-agent
  - systemctl disable --now packagekit
  - systemctl disable --now ModemManager
  - systemctl disable --now multipathd
  - hostnamectl set-hostname ${hostname}

final_message: "cloud-init finished"
```

Почему именно так:

* пользователь `ubuntu` доступен по SSH ключу
* пароль отключён
* `qemu-guest-agent` включается для работы с Proxmox
* отключаются лишние сервисы, которые обычно не нужны на серверной VM:

  * `packagekit` - GUI / D-Bus пакетный сервис
  * `ModemManager` - менеджер USB/LTE модемов
  * `multipathd` - multipath storage daemon

---

## Пример project-specific cloud-init

Например `cluster/cloud-config/vpn.yml`:

```yaml
#cloud-config

timezone: Europe/Moscow

users:
  - name: user
    groups: [sudo]
    shell: /bin/bash
    lock_passwd: true
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_key}

ssh_pwauth: false

package_update: true

packages:
  - qemu-guest-agent
  - wireguard
  - curl

write_files:
  - path: /etc/motd
    content: |
      VPN node managed by OpenTofu

runcmd:
  - systemctl enable --now qemu-guest-agent
  - systemctl disable --now packagekit
  - systemctl disable --now ModemManager
  - systemctl disable --now multipathd
  - hostnamectl set-hostname ${hostname}

final_message: "cloud-init finished"
```

---

## Быстрый запуск

Создать рабочий файл переменных:

```bash
cp ../terraform.tfvars.example terraform.tfvars
```

Инициализация:

```bash
cd cluster
tofu init
```

Проверка плана:

```bash
tofu plan
```

Применение:

```bash
tofu apply
```

---

## `.gitignore`

Минимально рекомендуется игнорировать:

```gitignore
**/.terraform/
**/.terraform.lock.hcl
**/*.tfstate
**/*.tfstate.*
**/*.tfvars
!**/*.tfvars.example
.env
.env.*
*.pem
*.key
*.log
.vscode/
.idea/
```

---

## Что хранить в git, а что нет

Хранить в git можно:

* `README.md`
* `terraform.tfvars.example`
* `cluster/*.tf`
* `cluster/cloud-config/*.yml`
* `modules/node/*.tf`
* `modules/node/cloud-config/default.yml`

Не хранить в git:

* `terraform.tfvars`
* `*.tfstate`
* `.terraform/`
* токены Proxmox
* приватные SSH ключи
* `.env`

---

## Отладка

Если cloud-init "не применился", проверять в первую очередь:

1. первая строка файла должна быть `#cloud-config`
2. cloud-init файл должен реально попасть в Proxmox
3. VM должна быть создана заново, если проверяется first boot логика
4. cloud image и template должны быть подготовлены корректно
5. если включён `qemu-guest-agent`, `tofu apply` может висеть в ожидании `guest-ping`, если агент не стартовал

Типовые причины проблем:

* отсутствует `#cloud-config`
* битый YAML
* неправильный override файл
* не тот cloud image / плохо подготовленный template
* ожидание `qemu-guest-agent` при неуспешном cloud-init

---

## Практические замечания

* если нельзя гарантировать интернет, лучше сразу готовить оффлайн провайдеры
* если не нужен парольный вход, лучше использовать только SSH ключи
* если нужен проектный `default.yml`, его можно положить в `cluster/cloud-config/default.yml`
* если нужен отдельный cloud-init для группы машин, можно указывать один и тот же файл в `cloudinit` у нескольких VM
* если нужна полная изоляция, можно задавать отдельный cloud-init на каждую VM

---

## Что обязательно должно быть

Если хотите воспроизвести этот проект в своей среде, вам в любом случае понадобятся:

* Ubuntu cloud image
* корректно подготовленный Proxmox template с cloud-init disk
* установленные OpenTofu провайдеры

Если этих компонентов нет, проект в полном виде воспроизвести нельзя.
