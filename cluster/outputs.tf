output "nodes_ipv4" {
  value = module.cluster.ip_addresses
}

output "nodes_hostnames" {
  value = module.cluster.hostnames
}

output "nodes_vmid" {
  value = module.cluster.vmids
}


