# Utility LXC Containers Environment - Using Shared LXC Module
# Dedicated environment for utility and infrastructure containers

# Utility LXC Configuration Map
locals {
  utility_containers = {
    "backup-server" = {
      description = "Backup and archival services container"
      cpu_cores   = 2
      memory      = 1024
      disk_size   = "50G"
      ip_address  = "192.168.1.180/24"
      tags        = "utility,backup,storage"
    }
    "log-collector" = {
      description = "Centralized logging container"
      cpu_cores   = 1
      memory      = 768
      disk_size   = "20G"
      ip_address  = "192.168.1.181/24"
      tags        = "utility,logging,infrastructure"
    }
    "file-server" = {
      description = "Network file sharing container"
      cpu_cores   = 1
      memory      = 512
      disk_size   = "30G"
      ip_address  = "192.168.1.182/24"
      tags        = "utility,files,storage"
    }
  }
}

# Create Utility LXC containers using the shared LXC module
module "utility_containers" {
  source = "../modules/lxc"  # 👈 Same shared LXC module

  for_each = local.utility_containers

  # Container Identity
  container_name = each.key
  description    = each.value.description

  # Proxmox Configuration
  target_node   = var.proxmox_node
  template_name = var.lxc_template

  # Resource Allocation
  cpu_cores = each.value.cpu_cores
  memory    = each.value.memory
  disk_size = each.value.disk_size

  # Network Configuration - Single Subnet
  ip_address = each.value.ip_address
  gateway    = var.network_gateway

  # SSH Configuration
  ssh_public_keys = var.ssh_public_key

  # Container Features
  enable_nesting = true  # Enable for Docker support
  privileged     = false # Maintain security

  # Startup Configuration
  start_on_create = true
  start_on_boot   = true

  # Organization
  tags = each.value.tags
}