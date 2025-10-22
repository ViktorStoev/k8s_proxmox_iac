locals {
  control_name = format("%s-%02d", var.vm_name_prefix, 1)
  worker_names = [
    for i in range(2, var.worker_count + 2) :
    format("%s-%02d", var.vm_name_prefix, i)
  ]
  nodes = toset(concat([local.control_name], local.worker_names))
}
