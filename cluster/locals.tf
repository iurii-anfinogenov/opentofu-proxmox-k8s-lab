# nodes — описание виртуальных машин
#
# - каждая VM описывается как набор ресурсов:
#     - CPU / memory
#     - disks (список дисков)
#     - network_devices (список сетевых интерфейсов)
#
# - модель полностью декларативная:
#     VM = набор дисков + набор NIC
#
# ------------------------------------------------------------------------------
# DISKS
# ------------------------------------------------------------------------------
#
# disks:
# - список дисков VM
# - порядок не критичен, но интерфейсы должны быть уникальны (scsi0, scsi1, ...)
#
# поля:
#
# datastore:
# - datastore в Proxmox
# - пример: local-lvm, ssd2
#
# interface:
# - имя интерфейса диска
# - пример: scsi0, scsi1, scsi2
# - ДОЛЖЕН быть уникален внутри VM
#
# size:
# - размер диска в GB
#
# import_from:
# - опционально
# - используется ТОЛЬКО для boot диска
# - формат: "<datastore>:<image>"
#
# ВАЖНО:
# - должен быть ровно один boot диск (import_from)
# - обычно:
#     scsi0 → boot диск
#     scsi1+ → data диски
#
# ------------------------------------------------------------------------------
# NETWORK
# ------------------------------------------------------------------------------
#
# network_devices:
# - список сетевых интерфейсов VM
#
# порядок:
# - [0] → eth0 (основной интерфейс)
# - [1] → eth1
# - [2] → eth2
#
# ВАЖНО:
# - порядок критичен
# - eth0 обычно management
# - неправильный порядок → потеря доступа к VM
#
# поля:
#
# bridge:
# - имя Proxmox bridge (vmbr0, vmbr1, ...)
# - ОБЯЗАТЕЛЬНО
#
# vlan_id:
# - опционально
# - если не указан → untagged
# - если указан → интерфейс в VLAN (bridge должен быть VLAN-aware)
#
# ip:
# - режим IP интерфейса
#
# варианты:
# - не указан → интерфейс без конфигурации (L2 only, без IP)
# - "dhcp" → включен DHCP
# - "192.168.x.x" → статический IP (требует cidr)
#
# cidr:
# - маска сети (например 24)
# - ОБЯЗАТЕЛЕН для статического IP
# - НЕ используется при dhcp
#
# gateway:
# - опционально
# - задаёт default route
# - должен быть указан только один раз на VM
# - обычно задаётся на eth0
#
# ВАЖНО:
# - отсутствие ip ≠ DHCP
# - DHCP задаётся только через ip = "dhcp"
# - интерфейс без ip → cloud-init его не конфигурирует
#
# ------------------------------------------------------------------------------
# CLOUD-INIT
# ------------------------------------------------------------------------------
#
# cloudinit:
# - имя cloud-init файла
#
# поиск:
# - cloud-config/<имя>.yml (root проекта)
# - если не найден → fallback:
#   modules/node/cloud-config/default.yml
#
# ------------------------------------------------------------------------------
# РЕКОМЕНДАЦИИ
# ------------------------------------------------------------------------------
#
# disks:
# - scsi0 → OS (boot)
# - scsi1+ → data / storage
#
# network:
# - eth0 → management (static IP + gateway)
# - eth1 → storage / overlay / secondary
#
# DHCP:
# - использовать только для вторичных интерфейсов
# - не задавать gateway вручную на DHCP интерфейсе
# - учитывать, что DHCP может выдать свой default route
#
# ------------------------------------------------------------------------------
# ПОВЕДЕНИЕ
# ------------------------------------------------------------------------------
#
# - network_devices → преобразуется в network_device + ip_config
# - соответствие строго по порядку:
#     network_devices[0] → eth0 → ip_config[0]
#     network_devices[1] → eth1 → ip_config[1]
#
# - ip_config создаётся только если:
#     - задан ip (static или dhcp)
#
# - если ip не задан:
#     - интерфейс создаётся
#     - но не конфигурируется внутри VM
#
# ------------------------------------------------------------------------------
locals {
  nodes = {
    k8s-master-1 = {
      cloudinit = "rocky.yml"
      index     = 1
      cpu       = var.worker_cpu
      memory    = 4092
      disks = [
        {
          datastore   = var.worker_datastore
          interface   = "scsi0"
          size        = var.worker_disk
          import_from = "${var.image_datastore}:${var.image_file}"
        }
      ]      
      network_devices = [
        {
          bridge  = var.node_bridge
          vlan_id = 20
          ip      = "192.168.20.11"
          cidr    = 24
          gateway = "192.168.20.1"
        }
      ]
    }
    # k8s-worker-1 = {
    #   cloudinit = "worker.yml"
    #   index     = 2
    #   cpu       = var.worker_cpu
    #   memory    = 8192
    #   disks = [
    #     {
    #       datastore   = var.worker_datastore
    #       interface   = "scsi0"
    #       size        = var.worker_disk
    #       import_from = "${var.image_datastore}:${var.image_file}"
    #     }
    #   ]      
    #   network_devices = [
    #     {
    #       bridge  = var.node_bridge
    #       vlan_id = 20
    #       ip      = "192.168.20.22"
    #       cidr    = 24
    #       gateway = "192.168.20.1"
    #     }
    #   ]
    # },    
    # k8s-worker-2 = {
    #   cloudinit = "worker.yml"
    #   index     = 3
    #   cpu       = var.worker_cpu
    #   memory    = 8192
    #   disks = [
    #     {
    #       datastore   = var.worker_datastore
    #       interface   = "scsi0"
    #       size        = var.worker_disk
    #       import_from = "${var.image_datastore}:${var.image_file}"
    #     },
    #     {
    #       datastore = "data1"
    #       interface = "scsi1"
    #       size      = 100
    #     }
    #   ]    
    #   network_devices = [
    #     {
    #       bridge  = var.node_bridge
    #       vlan_id = 20
    #       ip      = "192.168.20.23"
    #       cidr    = 24
    #       gateway = "192.168.20.1"
    #     },
    #     {
    #       bridge = "vmbr0" 
    #       ip     = "dhcp"
    #     }     
    #   ]
    # }     
  }
}