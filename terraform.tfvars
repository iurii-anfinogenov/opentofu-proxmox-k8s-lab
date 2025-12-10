proxmox_endpoint     = "https://192.168.22.5:8006/api2/json"
proxmox_token_id     = "terraform@pve!tofu"
proxmox_token_secret = "<secret>"


master_vmid_start = 4000
worker_vmid_start = 4010


master_cpu       = 2
master_memory    = 2048
master_disk      = 20
master_datastore = "local-lvm"

worker_cpu       = 2
worker_memory    = 4096
worker_disk      = 30
worker_datastore = "local-lvm"

image_datastore = "local"
image_file      = "import/ubuntu-24.qcow2"
cluster_gateway = "192.168.22.1"
network_base      = "192.168.22"
network_cidr      = "24"
cluster_ip_start  = 40
