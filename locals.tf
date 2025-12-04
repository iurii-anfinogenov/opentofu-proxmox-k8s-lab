locals {
  nodes = {
    master1 = {
      role      = "master"
      cpu       = var.master_cpu
      memory    = var.master_memory
      disk      = var.master_disk
      datastore = var.master_datastore
      ip_offset = var.master_ip_offset
    }

    worker1 = {
      role      = "worker"
      cpu       = var.worker_cpu
      memory    = var.worker_memory
      disk      = var.worker_disk
      datastore = var.worker_datastore
      ip_offset = var.worker_ip_offset
    }

    worker2 = {
      role      = "worker"
      cpu       = var.worker_cpu
      memory    = 8192
      disk      = var.worker_disk
      datastore = var.worker_datastore
      ip_offset = var.worker_ip_offset
    }
  }
}
