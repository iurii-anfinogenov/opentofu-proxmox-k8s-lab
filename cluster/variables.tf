variable "proxmox_endpoint" {}
variable "proxmox_token_id" {}
variable "proxmox_token_secret" {}

variable "proxmox_node" {
  type    = string
  default = "ve"
}

variable "cloudinit_datastore" {
  type    = string
  default = "local"
}

variable "disk_interface" {
  type    = string
  default = "virtio0"
}

variable "image_datastore" {
  type    = string
  default = "local"
}

variable "image_file" {
  type    = string
  default = "import/ubuntu-24.qcow2"
}

variable "worker_cpu" {
  default = 2
}


variable "worker_memory" {
  default = 2048
}


variable "worker_disk" {
  default = 20
}

variable "worker_ip_offset" {
  default = 5
}

variable "node_bridge" {
  default = "vmbr0"
}


variable "worker_datastore" {
  type    = string
  default = "local-lvm"
}



variable "worker_vmid_start" {
  type    = number
  default = 3000
}

variable "data_datastore" {
  type        = string
  default = "data1"
  description = "Datastore for VM data disks"
}

