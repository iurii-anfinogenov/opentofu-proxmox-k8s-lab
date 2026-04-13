data "local_file" "ssh_key" {
  filename = pathexpand("~/.ssh/id_rsa.pub")
}

module "cluster" {
  source = "../modules/node"

  nodes   = local.nodes
  ssh_key = trimspace(data.local_file.ssh_key.content)

  cluster_ip_start  = var.cluster_ip_start
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

  data_datastore = var.data_datastore
}
