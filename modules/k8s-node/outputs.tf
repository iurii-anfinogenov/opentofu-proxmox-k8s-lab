output "ip_addresses" {
  description = "IP addresses of all created nodes"
  value = {
    for name, _ in local.nodes :
    name => proxmox_virtual_environment_vm.nodes[name].ipv4_addresses[1][0]
  }
}

output "hostnames" {
  description = "Hostnames of all created nodes"
  value       = local.hostname_map
}

output "vmids" {
  description = "VMIDs of all created nodes"
  value       = local.vmid_map
}
