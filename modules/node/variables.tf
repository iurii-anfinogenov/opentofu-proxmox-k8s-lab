variable "ssh_key" {
  type = string
}

variable "nodes" {
  type = map(object({
    index     = number
    cpu       = number
    memory    = number
    vmid      = optional(number)
    cloudinit = optional(string)

    disks = list(object({
      datastore   = string
      interface   = string
      size        = number
      import_from = optional(string)
    }))

    network_devices = list(object({
      bridge  = string
      vlan_id = optional(number)

      ip      = optional(string)
      cidr    = optional(number)
      gateway = optional(string)
    }))
  }))

  # --- один boot диск ---
  validation {
    condition = alltrue([
      for node in var.nodes :
      length([
        for d in node.disks :
        d if try(d.import_from, null) != null
      ]) == 1
    ])
    error_message = "Each node must have exactly one boot disk (import_from)."
  }

  # --- уникальные интерфейсы дисков ---
  validation {
    condition = alltrue([
      for node in var.nodes :
      length(node.disks) == length(distinct([
        for d in node.disks : d.interface
      ]))
    ])
    error_message = "Disk interfaces must be unique per node (scsi0, scsi1, ...)."
  }

  # --- максимум один gateway ---
  validation {
    condition = alltrue([
      for node in var.nodes :
      length([
        for net in node.network_devices :
        net if try(net.gateway, null) != null
      ]) <= 1
    ])
    error_message = "Only one gateway is allowed per node."
  }

  # --- ip требует cidr ---
  validation {
    condition = alltrue([
      for node in var.nodes :
      alltrue([
        for net in node.network_devices :
        (
          try(net.ip, null) == null ||
          net.ip == "dhcp" ||
          try(net.cidr, null) != null
        )
      ])
    ])
    error_message = "If ip is set (not dhcp), cidr must also be set."
  }

  # --- cidr без ip запрещён ---
  validation {
    condition = alltrue([
      for node in var.nodes :
      alltrue([
        for net in node.network_devices :
        (
          try(net.cidr, null) == null ||
          (try(net.ip, null) != null && net.ip != "dhcp")
        )
      ])
    ])
    error_message = "cidr cannot be set without a static ip."
  }

  # --- минимум один NIC ---
  validation {
    condition = alltrue([
      for node in var.nodes :
      length(node.network_devices) >= 1
    ])
    error_message = "Each node must have at least one network_device."
  }
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
