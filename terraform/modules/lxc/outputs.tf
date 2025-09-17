# LXC Module Outputs - Information about created container

output "container_id" {
  description = "The container ID in Proxmox"
  value       = proxmox_lxc.container.vmid
}

output "container_name" {
  description = "The container hostname"
  value       = proxmox_lxc.container.hostname
}

output "container_node" {
  description = "The Proxmox node where container is located"
  value       = proxmox_lxc.container.target_node
}

output "container_ip_address" {
  description = "The container IP address"
  value       = split("/", proxmox_lxc.container.network[0].ip)[0]
}

output "ssh_command" {
  description = "SSH command to connect to the container"
  value       = "ssh -i ~/.ssh/proxmox_key root@${split("/", proxmox_lxc.container.network[0].ip)[0]}"
}

output "container_info" {
  description = "Complete container information"
  value = {
    id         = proxmox_lxc.container.vmid
    hostname   = proxmox_lxc.container.hostname
    node       = proxmox_lxc.container.target_node
    ip_address = split("/", proxmox_lxc.container.network[0].ip)[0]
    cores      = var.cpu_cores
    memory_mb  = var.memory
    disk_size  = var.disk_size
    template   = var.template_name
    privileged = var.privileged
  }
}