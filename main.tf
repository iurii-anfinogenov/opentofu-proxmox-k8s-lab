data "local_file" "ssh_key" {
  filename = pathexpand("~/.ssh/id_ed25519.pub")
}


module "cluster" {
  source = "./modules/k8s-node"

  nodes   = local.nodes
  ssh_key = trimspace(data.local_file.ssh_key.content)

  hostname_prefix   = var.hostname_prefix
  cluster_ip_start  = var.cluster_ip_start
  master_vmid_start = var.master_vmid_start
  worker_vmid_start = var.worker_vmid_start

  cloudinit_datastore = var.cloudinit_datastore
  proxmox_node        = var.proxmox_node

  node_bridge     = var.node_bridge
  image_datastore = var.image_datastore
  image_file      = var.image_file
  disk_interface  = var.disk_interface

  network_base    = var.network_base
  network_cidr    = var.network_cidr
  cluster_gateway = var.cluster_gateway
}
