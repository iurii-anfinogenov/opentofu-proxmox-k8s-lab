output "nodes_ipv4" {
  value = {
    for name, vm in proxmox_virtual_environment_vm.nodes :
    name => vm.ipv4_addresses
  }
}

output "nodes_hostnames" {
  value = {
    for name, node in local.nodes :
    name => "${var.hostname_prefix}-${node.role}-${node.index}"
  }
}

output "nodes_vmid" {
  value = local.vmid
}
