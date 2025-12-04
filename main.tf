resource "proxmox_virtual_environment_file" "cloudinit" {
  for_each     = local.nodes
  content_type = "snippets"
  datastore_id = var.cloudinit_datastore
  node_name    = var.proxmox_node

  source_raw {
    file_name = "${each.key}.yml"

    data = templatefile(
      "${path.module}/cloud-config/node-base.yml",
      {
        hostname = "${var.hostname_prefix}-${each.value.role}-${each.value.index}"
        ssh_key  = local.ssh_public_key
      }
    )
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  name      = "${var.hostname_prefix}-${each.value.role}-${each.value.index}"
  node_name = var.proxmox_node
  vm_id     = local.vmid[each.key]

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
  }

  memory {
    dedicated = each.value.memory
  }

  network_device {
    bridge = var.node_bridge
  }

  disk {
    datastore_id = each.value.datastore
    import_from  = "${var.image_datastore}:${var.image_file}"
    interface    = var.disk_interface
    size         = each.value.disk
  }

  initialization {
    datastore_id      = each.value.datastore
    user_data_file_id = proxmox_virtual_environment_file.cloudinit[each.key].id

    ip_config {
      ipv4 {
        address = "${var.network_base}.${local.ip_map[each.key]}/${var.network_cidr}"
        gateway = var.cluster_gateway
      }
    }
  }
}
