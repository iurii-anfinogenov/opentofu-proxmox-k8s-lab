# nodes — описание виртуальных машин
#
# vlan_id:
# - опциональный параметр
# - если НЕ указан → VM будет в обычной сети (untagged, vmbr0)
# - если указан → VM попадет в соответствующий VLAN (например 20 → 192.168.20.0/24)
# cloudinit:
# - опциональный параметр
# - указывает имя cloud-init файла для конкретной VM
# - файл должен находиться в root: cloud-config/<имя>.yml
# - если НЕ указан → используется "default.yml"
# - если файл НЕ найден в root → используется fallback из модуля (modules/node/cloud-config/default.yml)
#
# пример:
# - cloudinit = "worker.yml" → будет использован cloud-config/worker.yml
# - cloudinit не задан → будет использован default.yml

locals {
  nodes = {
     k8s-master-1 = {
      cloudinit = "master.yml"
      index     = 1
      cpu       = var.worker_cpu
      memory    = 8192      
      disk      = var.worker_disk
      datastore = var.worker_datastore
      ip_offset = 10
      vlan_id   = 20
    }
    
     k8s-worker-1 = {
      cloudinit = "worker.yml"
      index     = 2
      cpu       = 4
      memory    = 8192      
      disk      = var.worker_disk
      datastore = var.worker_datastore
      ip_offset = 20
      vlan_id   = 20
    }
     k8s-worker-2 = {
      cloudinit = "worker.yml"  
      index     = 3
      cpu       = 4
      memory    = 8192      
      disk      = var.worker_disk
      datastore = var.worker_datastore
      ip_offset = 20
      vlan_id   = 20
    }    
  }
}