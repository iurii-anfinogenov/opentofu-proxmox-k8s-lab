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

variable "hostname_prefix" {
  type    = string
  default = "k8s"
}

variable "master_cpu" {
  default = 2
}

variable "worker_cpu" {
  default = 2
}

variable "master_memory" {
  default = 4096
}

variable "worker_memory" {
  default = 4096
}

variable "master_disk" {
  default = 20
}

variable "worker_disk" {
  default = 20
}

variable "network_base" {
  default = "192.168.22"
}

variable "network_cidr" {
  default = "24"
}

variable "cluster_gateway" {
  default = "192.168.22.1"
}

variable "cluster_ip_start" {
  default = 40
}

variable "master_ip_offset" {
  default = 0
}

variable "worker_ip_offset" {
  default = 5
}

variable "node_bridge" {
  default = "vmbr0"
}
variable "master_datastore" {
  type    = string
  default = "local-lvm"
}

variable "worker_datastore" {
  type    = string
  default = "local-lvm"
}
variable "master_vmid_start" {
  type    = number
  default = 2000
}

variable "worker_vmid_start" {
  type    = number
  default = 2010
}
