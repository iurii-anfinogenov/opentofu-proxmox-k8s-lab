# OpenTofu + Proxmox 9.1.7 + Ubuntu Cloud-Init

---

## Обучение

Если хотите разобраться глубже, как это всё работает:

* Курс по OpenTofu / Terraform:
  [https://stepik.org/a/238385](https://stepik.org/a/238385)

---

## Контакты

Автор: Юрий Анфиногенов
Telegram: [https://t.me/uanfinogenov](https://t.me/uanfinogenov)

---

Подробное описание проекта для создания и управления виртуальными машинами в Proxmox через OpenTofu.

Этот вариант документации рассчитан на структуру, где используется одна рабочая директория `cluster/` и один общий модуль `modules/node`.

Документ описывает:

* установку OpenTofu
* оффлайн установку провайдеров
* настройку `~/.tofurc`
* подготовку cloud images
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
* Rocky Linux 9 cloud image
* OpenTofu

Если в вашей среде используются другие версии Proxmox, cloud image или провайдеров, поведение может отличаться.

---

## Важно

Перед использованием необходимо проверить и при необходимости изменить переменные под свою среду.

Чаще всего отличаются:

* datastore (`local`, `local-lvm`, `ssd2` и т.д.)
* `image_datastore` и путь к образу
* bridge (`vmbr0`)
* VLAN
* IP адресация

Значения в примере не универсальны и зависят от конкретного Proxmox окружения.

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
* bootstrap настройку

Ключевой принцип проекта:

* OpenTofu не должен подробно конфигурировать ОС
* cloud-init не должен управлять инфраструктурой Proxmox

---

## Структура проекта

```text
.
├── README.md
├── cluster
│   ├── cloud-config
│   ├── locals.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── variables.tf
├── modules
│   └── node
└── terraform.tfvars.example
```

Где:

* `cluster/` - рабочее окружение
* `cluster/cloud-config/` - project-specific cloud-init файлы (`worker.yml`, `rocky.yml`, `default.yml`)
* `modules/node/` - общий модуль VM
* `modules/node/cloud-config/default.yml` - fallback cloud-init
* `terraform.tfvars.example` - пример переменных без секретов

---

## Как работает cloud-init

Для каждой VM модуль выбирает cloud-init файл по следующему правилу:

1. если у VM задан параметр `cloudinit`, используется `cluster/cloud-config/<имя>`
2. если параметр не задан, используется `cluster/cloud-config/default.yml`
3. если файла нет, используется fallback: `modules/node/cloud-config/default.yml`

Это даёт три уровня конфигурации:

* per-VM cloud-init
* project default cloud-init
* module fallback cloud-init

---

## Подготовка cloud images

Проект использует qcow2 cloud images напрямую через `import_from`.

Образы хранятся в:

```text
/var/lib/vz/import/
```

### Ubuntu 24.04

```bash
cd /var/lib/vz/import

wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img \
  -O ubuntu-24.qcow2
```

### Rocky Linux 9

```bash
cd /var/lib/vz/import

wget https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2 \
  -O rocky9.qcow2
```

Важно:

* используются именно cloud images
* VM создаются напрямую из qcow2
* template workflow в проекте не используется

---

## Установка OpenTofu

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://get.opentofu.org/opentofu.gpg \
  | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null

curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
  | sudo gpg --no-tty --batch --dearmor \
    -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null

sudo chmod a+r \
  /etc/apt/keyrings/opentofu.gpg \
  /etc/apt/keyrings/opentofu-repo.gpg

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

Проверка:

```bash
go version
```

---

## Настройка оффлайн-провайдеров

Если OpenTofu должен работать без интернета, провайдеры можно положить в:

```text
~/.terraform.d/plugins/
```

Создание каталогов:

```bash
mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/bpg/proxmox
mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/hashicorp/{local,random,tls}
```

---

## Настройка `~/.tofurc`

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

---

## Доступ к Proxmox API

Минимальные права для API token:

* `Datastore.AllocateSpace`
* `VM.Allocate`
* `VM.Audit`
* `VM.Config.*`

Пример файла:

```bash
vim ~/.pve-creds
```

```bash
export PVE_TOKEN_ID="root@pam!tofu"
export PVE_TOKEN_SECRET="YOUR_SECRET"
export PVE_HOST="192.168.22.5"
```

Загрузка:

```bash
set -a
source ~/.pve-creds
set +a
```

Проверка:

```bash
curl -k \
  -H "Authorization: PVEAPIToken=${PVE_TOKEN_ID}=${PVE_TOKEN_SECRET}" \
  https://$PVE_HOST:8006/api2/json/version
```

---

## Пример описания `nodes`

```hcl
nodes = map(object({
  index     = number
  cpu       = number
  memory    = number
  vmid      = optional(number)
  cloudinit = optional(string)

  disks = list(object({
    datastore   = string
    interface   = string
    size        = number
    import_from = optional(string)
  }))

  network_devices = list(object({
    bridge  = string
    vlan_id = optional(number)

    ip      = optional(string)
    cidr    = optional(number)
    gateway = optional(string)
  }))
}))
```

---

## DISKS

Пример:

```hcl
disks = [
  {
    datastore   = "ssd2"
    interface   = "scsi0"
    size        = 20
    import_from = "local:import/ubuntu-24.qcow2"
  },
  {
    datastore = "data1"
    interface = "scsi1"
    size      = 100
  }
]
```

Правила:

* `scsi0` обычно root disk
* `scsi1+` дополнительные диски
* интерфейсы должны быть уникальными

---

## NETWORK

Сеть задаётся на уровне интерфейса.

Порядок:

```text
[0] -> eth0
[1] -> eth1
```

Обычно:

* `eth0` - management
* `eth1` - secondary/storage

### Static

```hcl
ip      = "192.168.20.10"
cidr    = 24
gateway = "192.168.20.1"
```

### DHCP

```hcl
ip = "dhcp"
```

### L2 only

```hcl
# ip не задан
```

Важно:

* отсутствие `ip` не равно DHCP
* gateway должен быть только один
* обычно gateway задаётся на `eth0`

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

План:

```bash
tofu plan
```

Применение:

```bash
tofu apply
```

---

## `.gitignore`

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

## Что хранить в git

Можно хранить:

* `README.md`
* `terraform.tfvars.example`
* `cluster/*.tf`
* `cluster/cloud-config/*.yml`
* `modules/node/*.tf`

Не хранить:

* `terraform.tfvars`
* `.terraform/`
* `*.tfstate`
* токены
* приватные SSH ключи
* `.env`

---

## Отладка

Если cloud-init не применился:

1. проверить `#cloud-config`
2. проверить YAML
3. проверить cloud image
4. проверить qemu-guest-agent
5. пересоздать VM для проверки first boot логики

Полезные команды:

```bash
cloud-init status --long
```

```bash
journalctl -u cloud-init
```

```bash
ip r
```

```bash
lsblk
```

---

## Практические замечания

* лучше использовать SSH ключи
* gateway должен быть только один
* cloud-init применяется на first boot
* существующим VM лучше не менять disk interface
* дополнительные диски должны иметь уникальные интерфейсы

---

## Что обязательно должно быть

Для работы проекта необходимы:

* Ubuntu/Rocky cloud images
* каталог `/var/lib/vz/import/`
* OpenTofu providers
* доступ к Proxmox API
