# Output VM information for easy access
output "vm_info" {
  description = "Test VM information"
  value = {
    name = proxmox_vm_qemu.test_server.name
    vmid = proxmox_vm_qemu.test_server.vmid
    node = proxmox_vm_qemu.test_server.target_node
  }
}

# Output IP address once VM is running
output "vm_ip" {
  description = "Test VM IP address"
  value       = proxmox_vm_qemu.test_server.default_ipv4_address
}

# Output ready-to-use SSH command
output "ssh_command" {
  description = "SSH command to connect to test VM"
  value       = "ssh -i ~/.ssh/proxmox_key ubuntu@${proxmox_vm_qemu.test_server.default_ipv4_address}"
}

# LXC Container outputs
output "lxc_containers" {
  description = "Information about test LXC containers"
  value = {
    for i, container in proxmox_lxc.test_containers : 
    container.hostname => {
      vmid = container.vmid
      ip   = split("/", container.network[0].ip)[0]
      node = container.target_node
      ssh_command = "ssh -i ~/.ssh/proxmox_key root@${split("/", container.network[0].ip)[0]}"
    }
  }
}

# Summary output
output "test_infrastructure_summary" {
  description = "Summary of test infrastructure"
  value = {
    test_vm = {
      name = proxmox_vm_qemu.test_server.name
      ip   = proxmox_vm_qemu.test_server.default_ipv4_address
    }
    lxc_containers = length(proxmox_lxc.test_containers)
    total_resources = 1 + length(proxmox_lxc.test_containers)
    ip_range = "${var.network_base}.100 (VM), ${var.network_base}.110-${110 + var.lxc_count - 1} (LXC)"
  }
}