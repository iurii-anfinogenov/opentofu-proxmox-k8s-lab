variable "proxmox_endpoint" {
  type = string
}
variable "proxmox_token_id" {
  type      = string
  sensitive = true
}
variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

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
  default = "scsi0"
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
  type    = number
}


variable "worker_memory" {
  type    = number
  default = 2048
}


variable "worker_disk" {
  type    = number
  default = 20
}

variable "node_bridge" {
  type    = string
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
  default     = "data1"
  description = "Datastore for VM data disks"
}

