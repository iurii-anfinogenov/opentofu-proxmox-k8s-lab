terraform {
  required_providers {
    proxmox = {
      source = "registry.opentofu.org/bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_file" "cloudinit" {
  for_each     = local.nodes
  content_type = "snippets"
  datastore_id = var.cloudinit_datastore
  node_name    = var.proxmox_node

  source_raw {
    file_name = "${each.key}.yml"
    data = fileexists("${path.root}/cloud-config/${coalesce(each.value.cloudinit, "default.yml")}") ? templatefile(
      "${path.root}/cloud-config/${coalesce(each.value.cloudinit, "default.yml")}",
      {
        hostname = local.hostname_map[each.key]
        ipv4     = each.value.network_devices[0].ip
        ssh_key  = local.ssh_public_key
      }
    ) : templatefile(
      "${path.module}/cloud-config/default.yml",
      {
        hostname = local.hostname_map[each.key]
        ipv4     = each.value.network_devices[0].ip
        ssh_key  = local.ssh_public_key
      }
    )
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes
  tags = ["tofu"]

  name      = local.hostname_map[each.key]
  node_name = var.proxmox_node

  vm_id = coalesce(
    lookup(local.nodes[each.key], "vmid", null),
    local.vmid_map[each.key]
  )

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"

  }

  memory {
    dedicated = each.value.memory
  }

  dynamic "network_device" {
    for_each = each.value.network_devices

    content {
      bridge  = network_device.value.bridge
      vlan_id = try(network_device.value.vlan_id, null)
    }
  }

  dynamic "clone" {
    for_each = try(each.value.template_id, null) == null ? [] : [each.value.template_id]

    content {
      vm_id = clone.value
    }
  }

  dynamic "disk" {
    for_each = try(each.value.template_id, null) == null ? [1] : []

    content {
      datastore_id = each.value.datastore
      import_from  = "${var.image_datastore}:${coalesce(each.value.image_file, var.image_file)}"
      interface    = var.disk_interface
      size         = each.value.disk
    }
  }

  dynamic "disk" {
    for_each = try(each.value.data_disk, null) == null ? [] : [each.value.data_disk]

    content {
      datastore_id = var.data_datastore
      interface    = "scsi1"
      size         = disk.value
    }
  }
 
  dynamic "disk" {
    for_each = try(each.value.disks, null) != null ? each.value.disks : []

    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size_gb
    }
  }

  initialization {
    datastore_id      = each.value.datastore
    user_data_file_id = proxmox_virtual_environment_file.cloudinit[each.key].id

    dynamic "ip_config" {
      for_each = each.value.network_devices

      content {
        ipv4 {
          address = try(ip_config.value.ip, "dhcp") == null ? "dhcp" : "${ip_config.value.ip}/${ip_config.value.cidr}"
          gateway = try(ip_config.value.gateway, null)
        }
      }
    }
  }
}
