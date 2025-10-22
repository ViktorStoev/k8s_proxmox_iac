variable "pm_api_url" {}
variable "pm_api_token_id" {}
variable "pm_api_token_secret" { sensitive = true }

variable "pm_target_node" { default = "NEO-srv" }
variable "template_name" { default = "ubuntu-22.04-cloudinit-tpl" }
variable "vm_name_prefix" { default = "k8s-ubuntu" }

variable "control_count" { default = 1 }
variable "worker_count" { default = 2 }

variable "cpu_cores" { default = 2 }
variable "cpu_sockets" { default = 1 }
variable "memory_mb" { default = 4096 }
variable "disk_gb" { default = 30 }
variable "storage" { default = "local-lvm" }
variable "bridge" { default = "vmbr0" }

variable "ci_user" { default = "ubuntu" }
variable "ci_password" { default = "changeme" }
variable "ssh_pubkey_path" { default = "~/.ssh/id_ed25519.pub" }
variable "ssh_private_key_path" { default = "~/.ssh/id_ed25519" }
