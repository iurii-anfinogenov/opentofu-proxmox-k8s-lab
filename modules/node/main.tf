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
        hostname      = local.hostname_map[each.key]
        ssh_key       = local.ssh_public_key
      }
    ) : templatefile(
      "${path.module}/cloud-config/default.yml",
      {
        hostname      = local.hostname_map[each.key]
        ssh_key       = local.ssh_public_key
      }
    )   
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  name      = local.hostname_map[each.key]
  node_name = var.proxmox_node

  # allow vmid override
  vm_id = coalesce(
    lookup(local.nodes[each.key], "vmid", null),
    local.vmid_map[each.key]
  )

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
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
dynamic "disk" {
  for_each = each.value.disks

  content {
    datastore_id = disk.value.datastore
    interface    = disk.value.interface
    size         = disk.value.size

    # только для первого (boot) диска
    import_from = try(disk.value.import_from, "")
  }
}

initialization {
  datastore_id = [
    for d in each.value.disks :
    d.datastore if try(d.import_from, null) != null
  ][0]
  user_data_file_id = proxmox_virtual_environment_file.cloudinit[each.key].id

dynamic "ip_config" {
  for_each = [
    for net in each.value.network_devices :
    net if try(net.ip, null) != null
  ]

  content {
    ipv4 {
      address = ip_config.value.ip == "dhcp" ? "dhcp" : "${ip_config.value.ip}/${coalesce(ip_config.value.cidr, 24)}"
      gateway = try(ip_config.value.gateway, null)
    }
  }
}
}
}