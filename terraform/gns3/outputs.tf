# GNS3 Server outputs
output "gns3_servers" {
  description = "Information about GNS3 servers"
  value = {
    for i, server in proxmox_vm_qemu.gns3_server : 
    server.name => {
      vmid = server.vmid
      ip   = server.default_ipv4_address
      node = server.target_node
      ssh_command = "ssh -i ~/.ssh/proxmox_key ubuntu@${server.default_ipv4_address}"
    }
  }
}

# Summary output
output "gns3_infrastructure_summary" {
  description = "Summary of GNS3 infrastructure"
  value = {
    gns3_servers = length(proxmox_vm_qemu.gns3_server)
    total_cpu_cores = var.gns3_server_count * var.gns3_server_cores
    total_memory_gb = (var.gns3_server_count * var.gns3_server_memory) / 1024
    ip_range = "${var.network_base}.20-${20 + var.gns3_server_count - 1}"
  }
}

# Ready-to-use SSH commands
output "ssh_commands" {
  description = "SSH commands for all GNS3 servers"
  value = [
    for server in proxmox_vm_qemu.gns3_server :
    "ssh -i ~/.ssh/proxmox_key ubuntu@${server.default_ipv4_address}  # ${server.name}"
  ]
}