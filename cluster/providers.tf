terraform {
  required_providers {
    proxmox = {
      source = "registry.opentofu.org/bpg/proxmox"
      version = "= 0.101.1"
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
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }
}  