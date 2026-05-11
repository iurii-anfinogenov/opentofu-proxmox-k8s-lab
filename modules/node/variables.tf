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
    vmid      = optional(number)
    data_disk = optional(number)
    cloudinit = optional(string)
    template_id = optional(number)
    image_file = optional(string)

    network_devices = list(object({
      bridge  = string
      vlan_id = optional(number)

      ip      = optional(string)
      cidr    = optional(number)
      gateway = optional(string)
    }))

    disks = optional(list(object({
      size_gb         = number
      datastore_id    = string
      interface       = string
    })))
  }))
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

variable "data_datastore" {
  type        = string
  description = "Datastore for data disk"
}
