terraform {
  required_providers {
    proxmox = { source = "Telmate/proxmox", version = "3.0.2-rc04" }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "vm" {
  for_each    = { for name in local.nodes : name => name }
  name        = each.key
  target_node = var.pm_target_node
  clone       = var.template_name
  full_clone  = true
  agent       = 1
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  cpu {
    type    = "host"
    sockets = var.cpu_sockets
    cores   = var.cpu_cores
  }

  memory = var.memory_mb

  disk {
    slot     = "scsi0"
    type     = "disk"
    storage  = var.storage
    size     = "${var.disk_gb}G"
    iothread = true
    discard  = true
  }

  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.storage
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.bridge
  }

  ipconfig0  = "ip=dhcp"
  ciuser     = var.ci_user
  cipassword = var.ci_password
  sshkeys    = file(var.ssh_pubkey_path)
  cicustom   = "vendor=local:snippets/ubuntu-ci.yaml"
  vga { type = "std" }

  additional_wait = 15
}

output "inventory" {
  value = {
    control = [proxmox_vm_qemu.vm[local.control_name].default_ipv4_address]
    workers = [for n in local.worker_names : proxmox_vm_qemu.vm[n].default_ipv4_address]
  }
}

resource "local_file" "inventory_ini" {
  filename = "${path.module}/../ansible/inventory/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.ini.tmpl", {
    control_name = local.control_name
    control_ip   = proxmox_vm_qemu.vm[local.control_name].default_ipv4_address
    worker_map = {
      for n in local.worker_names :
      n => proxmox_vm_qemu.vm[n].default_ipv4_address
    }
    ansible_user  = var.ci_user
    identity_file = var.ssh_private_key_path
  })
}

resource "local_file" "ssh_config" {
  filename = "${path.module}/../ansible/inventory/ssh_config"
  content = templatefile("${path.module}/templates/ssh_config.tmpl", {
    hosts = merge(
      { (local.control_name) = proxmox_vm_qemu.vm[local.control_name].default_ipv4_address },
      { for n in local.worker_names : n => proxmox_vm_qemu.vm[n].default_ipv4_address }
    )
    user          = var.ci_user
    identity_file = var.ssh_private_key_path
  })
}

