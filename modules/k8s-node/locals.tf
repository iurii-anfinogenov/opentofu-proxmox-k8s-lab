locals {
  # ssh-ключ приходит снаружи, файл не читаем
  ssh_public_key = var.ssh_key

  # Разделяем ноды по ролям
  masters = {
    for name, node in var.nodes :
    name => node if node.role == "master"
  }

  workers = {
    for name, node in var.nodes :
    name => node if node.role == "worker"
  }

  # Даём каждой ноде индекс внутри своей роли (master1, master2, worker1...)
  # Индекс определяется по отсортированным именам, чтобы был стабильным.
  indexed_masters = {
    for name, node in local.masters :
    name => merge(node, {
      index = index(sort(keys(local.masters)), name) + 1
    })
  }

  indexed_workers = {
    for name, node in local.workers :
    name => merge(node, {
      index = index(sort(keys(local.workers)), name) + 1
    })
  }

  # Общая карта нод: уже с полем index внутри
  nodes = merge(local.indexed_masters, local.indexed_workers)

  # IP-адреса: сохраняем логику с ip_offset
  ip_map = {
    for name, node in local.nodes :
    name => var.cluster_ip_start + node.ip_offset + node.index
  }

  # VMID: разные диапазоны для master/worker
  vmid_map = {
    for name, node in local.nodes :
    name => (
      node.role == "master"
      ? var.master_vmid_start + node.index
      : var.worker_vmid_start + node.index
    )
  }

  # hostname: prefix-role-index (k8s-master-1, k8s-worker-2 и т.п.)
  hostname_map = {
    for name, node in local.nodes :
    name => "${var.hostname_prefix}-${node.role}-${node.index}"
  }
}
