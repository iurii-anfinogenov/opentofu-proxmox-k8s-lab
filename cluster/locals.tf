# nodes - описание VM.
#
# network_devices:
# - порядок = eth0, eth1 ...
# - eth0: management, VLAN 20, 192.168.20.0/24, с gateway
# - eth1: secondary/storage, untagged, 192.168.22.0/24, без gateway
# - gateway указывать только на одном интерфейсе
#
# disks:
# - root disk использует var.disk_interface (рекомендуется scsi0)
# - data_disk - один дополнительный диск на var.data_datastore
# - disks - произвольные дополнительные диски
# - каждый дополнительный диск должен иметь уникальный interface:
#   scsi1, scsi2, scsi3 ...
#
# recommended layout:
# - scsi0 = root disk
# - scsi1 = first data disk
# - scsi2 = second data disk
#
# cloudinit:
# - worker.yml для Ubuntu
# - rocky.yml для Rocky
#
# images:
# - import/ubuntu-24.qcow2
# - import/rocky9.qcow2
#
# datastore examples:
# - ssd2      - fast VM/root disks
# - local-lvm - standard VM storage
# - data1     - large data disks

locals {
  vm_defaults = {
    cpu       = var.worker_cpu
    memory    = var.worker_memory
    disk      = var.worker_disk
    datastore = var.worker_datastore
    cloudinit = "ubuntu.yml"
  }

  net_mgmt = {
    bridge  = var.node_bridge
    vlan_id = 20
    cidr    = 24
    gateway = "192.168.20.1"
  }

  net_secondary = {
    bridge = var.node_bridge
    cidr   = 24
  }

  nodes = {
    # Ubuntu, root disk on ssd2, one VLAN 20 interface
    lab-1 = merge(local.vm_defaults, {
      image_file = "import/ubuntu-24.qcow2"
      index      = 1
      datastore  = "ssd2"

      network_devices = [
        merge(local.net_mgmt, {
          ip = "192.168.20.11"
        })
      ]
    })

    # Rocky, root disk on local-lvm, one VLAN 20 interface
    lab-2 = merge(local.vm_defaults, {
      image_file = "import/rocky9.qcow2"
      cloudinit  = "rocky.yml"
      index      = 2
      cpu        = 4
      memory     = 4096
      datastore  = "local-lvm"

      network_devices = [
        merge(local.net_mgmt, {
          ip = "192.168.20.12"
        })
      ]
    })

    # Rocky, root disk on ssd2, one data disk on data1
    lab-3 = merge(local.vm_defaults, {
      image_file = "import/rocky9.qcow2"
      cloudinit  = "rocky.yml"
      index      = 3
      cpu        = 8
      memory     = 8192
      datastore  = "ssd2"
      data_disk  = 100

      network_devices = [
        merge(local.net_mgmt, {
          ip = "192.168.20.13"
        })
      ]
    })

    # Ubuntu, root disk on local-lvm, two interfaces:
    # eth0 VLAN 20: 192.168.20.0/24
    # eth1 untagged: 192.168.22.0/24
    lab-4 = merge(local.vm_defaults, {
      image_file = "import/ubuntu-24.qcow2"
      cloudinit  = "ubuntu.yml"
      index      = 4
      cpu        = 4
      memory     = 4096
      datastore  = "local-lvm"

      network_devices = [
        merge(local.net_mgmt, {
          ip = "192.168.20.14"
        }),
        merge(local.net_secondary, {
          ip = "192.168.22.14"
        })
      ]
    })

    # Rocky, root disk on ssd2, multiple custom data disks
    lab-5 = merge(local.vm_defaults, {
      image_file = "import/rocky9.qcow2"
      cloudinit  = "rocky.yml"
      index      = 5
      cpu        = 4
      memory     = 4096
      datastore  = "ssd2"

      disks = [
        {
          size_gb      = 100
          datastore_id = "data1"
          interface    = "scsi1"
        },
        {
          size_gb      = 200
          datastore_id = "ssd2"
          interface    = "scsi2"
        }
      ]

      network_devices = [
        merge(local.net_mgmt, {
          ip = "192.168.20.15"
        }),
        merge(local.net_secondary, {
          ip = "192.168.22.15"
        })
      ]
    })
  }
}