locals {
  nodes = {
    master1 = {
      role      = "master"
      index     = 1
      cpu       = var.master_cpu
      memory    = var.master_memory
      disk      = var.master_disk
      datastore = var.master_datastore
      ip_offset = var.master_ip_offset
    }

    worker1 = {
      role      = "worker"
      index     = 1
      cpu       = var.worker_cpu
      memory    = var.worker_memory
      disk      = var.worker_disk
      datastore = var.worker_datastore
      ip_offset = var.worker_ip_offset
    }

    worker2 = {
      role      = "worker"
      index     = 2
      cpu       = var.worker_cpu
      memory    = var.worker_memory
      disk      = var.worker_disk
      datastore = var.worker_datastore
      ip_offset = var.worker_ip_offset
    }    
  }
}