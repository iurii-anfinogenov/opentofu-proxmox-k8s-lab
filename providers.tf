terraform {
  required_providers {
    proxmox = {
      source = "registry.opentofu.org/bpg/proxmox"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure  = true

  ssh {
    username    = "root"
    agent       = true
    private_key = file("~/.ssh/id_ed25519")
  }
}  