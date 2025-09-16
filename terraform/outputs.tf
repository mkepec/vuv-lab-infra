# Output values for all provisioned infrastructure

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

# Docker Host outputs
output "docker_hosts" {
  description = "Information about Docker hosts"
  value = {
    for i, host in proxmox_vm_qemu.docker_host : 
    host.name => {
      vmid = host.vmid
      ip   = host.default_ipv4_address
      node = host.target_node
      ssh_command = "ssh -i ~/.ssh/proxmox_key ubuntu@${host.default_ipv4_address}"
    }
  }
}

# Utility Container outputs
output "utility_containers" {
  description = "Information about utility LXC containers"
  value = {
    for i, container in proxmox_lxc.utility_services : 
    container.hostname => {
      vmid = container.vmid
      ip   = container.network[0].ip
      node = container.target_node
      ssh_command = "ssh -i ~/.ssh/proxmox_key root@${split("/", container.network[0].ip)[0]}"
    }
  }
}

# Summary output
output "infrastructure_summary" {
  description = "Summary of all provisioned infrastructure"
  value = {
    gns3_servers = length(proxmox_vm_qemu.gns3_server)
    docker_hosts = length(proxmox_vm_qemu.docker_host)
    utility_containers = length(proxmox_lxc.utility_services)
    total_resources = length(proxmox_vm_qemu.gns3_server) + length(proxmox_vm_qemu.docker_host) + length(proxmox_lxc.utility_services)
  }
}

# Ansible inventory helper
output "ansible_inventory" {
  description = "Ansible inventory information"
  value = {
    gns3_servers = [
      for server in proxmox_vm_qemu.gns3_server : {
        name = server.name
        ip   = server.default_ipv4_address
        ansible_host = server.default_ipv4_address
        ansible_user = "ubuntu"
        ansible_ssh_private_key_file = "~/.ssh/proxmox_key"
      }
    ]
    docker_hosts = [
      for host in proxmox_vm_qemu.docker_host : {
        name = host.name
        ip   = host.default_ipv4_address
        ansible_host = host.default_ipv4_address
        ansible_user = "ubuntu"
        ansible_ssh_private_key_file = "~/.ssh/proxmox_key"
      }
    ]
    utility_containers = [
      for container in proxmox_lxc.utility_services : {
        name = container.hostname
        ip   = split("/", container.network[0].ip)[0]
        ansible_host = split("/", container.network[0].ip)[0]
        ansible_user = "root"
        ansible_ssh_private_key_file = "~/.ssh/proxmox_key"
      }
    ]
  }
}