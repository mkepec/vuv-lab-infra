# VM Module Outputs - Information about created VM

output "vm_id" {
  description = "The VM ID in Proxmox"
  value       = proxmox_vm_qemu.vm.vmid
}

output "vm_name" {
  description = "The VM name"
  value       = proxmox_vm_qemu.vm.name
}

output "vm_node" {
  description = "The Proxmox node where VM is located"
  value       = proxmox_vm_qemu.vm.target_node
}

output "vm_ip_address" {
  description = "The VM IP address"
  value       = proxmox_vm_qemu.vm.default_ipv4_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i ~/.ssh/proxmox_key ${var.ci_user}@${proxmox_vm_qemu.vm.default_ipv4_address}"
}

output "vm_info" {
  description = "Complete VM information"
  value = {
    id          = proxmox_vm_qemu.vm.vmid
    name        = proxmox_vm_qemu.vm.name
    node        = proxmox_vm_qemu.vm.target_node
    ip_address  = proxmox_vm_qemu.vm.default_ipv4_address
    cpu_cores   = var.cpu_cores
    memory_mb   = var.memory
    disk_size   = var.disk_size
    template    = var.template_name
  }
}