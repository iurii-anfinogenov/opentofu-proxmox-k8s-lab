locals {
  ssh_public_key = var.ssh_key
  nodes          = var.nodes

  masters = {
    for name, node in local.nodes :
    name => node if node.role == "master"
  }

  workers = {
    for name, node in local.nodes :
    name => node if node.role == "worker"
  }

  ip_map = {
    for name, node in local.nodes :
    name => var.cluster_ip_start + node.ip_offset + node.index
  }

  vmid_map = {
    for name, node in local.nodes :
    name => (
      node.role == "master"
      ? var.master_vmid_start + node.index
      : var.worker_vmid_start + node.index
    )
  }

  hostname_map = {
    for name, node in local.nodes :
    name => "${var.hostname_prefix}-${node.role}-${node.index}"
  }
}