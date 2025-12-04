locals {
  ssh_public_key = trimspace(file("~/.ssh/id_ed25519.pub"))

  masters = {
    for i in range(var.master_count) :
    "master${i + 1}" => {
      role      = "master"
      index     = i + 1
      cpu       = var.master_cpu
      memory    = var.master_memory
      disk      = var.master_disk
      datastore = var.master_datastore
      ip_offset = var.master_ip_offset
    }
  }

  workers = {
    for i in range(var.worker_count) :
    "worker${i + 1}" => {
      role      = "worker"
      index     = i + 1
      cpu       = var.worker_cpu
      memory    = var.worker_memory
      disk      = var.worker_disk
      datastore = var.worker_datastore
      ip_offset = var.worker_ip_offset
    }
  }

  nodes = merge(local.masters, local.workers)

  ip_map = {
    for name, node in local.nodes :
    name => var.cluster_ip_start + node.ip_offset + node.index
  }

  vmid = {
    for name, node in local.nodes :
    name => (
  node.role == "master"
    ? var.master_vmid_start + node.index
    : var.worker_vmid_start + node.index

    )
  }
}
