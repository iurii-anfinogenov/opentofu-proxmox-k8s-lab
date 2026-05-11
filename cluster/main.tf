data "local_file" "ssh_key" {
  filename = pathexpand("~/.ssh/id_rsa.pub")
}

module "cluster" {
  source = "../modules/node"

  nodes   = local.nodes
  ssh_key = trimspace(data.local_file.ssh_key.content)

  worker_vmid_start = var.worker_vmid_start

  cloudinit_datastore = var.cloudinit_datastore
  proxmox_node        = var.proxmox_node

  node_bridge     = var.node_bridge
  image_datastore = var.image_datastore
  image_file      = var.image_file
  disk_interface  = var.disk_interface

  data_datastore = var.data_datastore
}
