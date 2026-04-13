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

  network_device {
    bridge = var.node_bridge
    # vlan_id = try(each.value.vlan_id, null)    
    vlan_id = each.value.vlan_id

  }

  disk {
    datastore_id = each.value.datastore
    import_from  = "${var.image_datastore}:${var.image_file}"
    interface    = var.disk_interface
    size         = each.value.disk
  }

  dynamic "disk" {
    for_each = try([each.value.data_disk], [])

    content {
      datastore_id = var.data_datastore
      interface    = "scsi1"
      size         = disk.value
    }
  }

  initialization {
    datastore_id      = each.value.datastore
    user_data_file_id = proxmox_virtual_environment_file.cloudinit[each.key].id

ip_config {
  ipv4 {
    address = "${local.ip_map[each.key]}/${var.network_cidr}"
    gateway = var.cluster_gateway
  }
}
  }
}