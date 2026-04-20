locals {
  ssh_public_key = var.ssh_key

  nodes = {
    for name, node in var.nodes :
    name => node
  }



vmid_map = {
  for name, node in local.nodes :
  name => coalesce(
    lookup(node, "vmid", null),
    var.worker_vmid_start + node.index
  )
}

  hostname_map = {
    for name, node in local.nodes :
    name => "${name}"
  }
}
