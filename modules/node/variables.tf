variable "ssh_key" {
  type = string
}

variable "nodes" {
  type = map(object({
    index     = number
    cpu       = number
    memory    = number
    disk      = number
    datastore = string
    ip_offset = optional(number)
    ip        = optional(string)
    vmid      = optional(number)
    vlan_id   = optional(number)
    data_disk = optional(number)
    cloudinit = optional(string)
  }))
}

variable "cluster_ip_start" {
  type = number
}

variable "worker_vmid_start" {
  type = number
}

variable "cloudinit_datastore" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "node_bridge" {
  type = string
}

variable "image_datastore" {
  type = string
}

variable "image_file" {
  type = string
}

variable "disk_interface" {
  type = string
}

variable "network_base" {
  type = string
}

variable "network_cidr" {
  type = number
}

variable "cluster_gateway" {
  type = string
}



variable "data_datastore" {
  type        = string
  description = "Datastore for data disk"
}
