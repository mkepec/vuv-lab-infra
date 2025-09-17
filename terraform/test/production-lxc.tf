# Production LXC Containers Configuration - Using Shared LXC Module
# Single Subnet Approach (192.168.1.x)

# Production LXC Configuration Map
locals {
  production_lxc = {
    "dns-server" = {
      description = "BIND DNS server container"
      cpu_cores   = 1
      memory      = 512
      disk_size   = "8G"
      ip_address  = "192.168.1.170/24"
      tags        = "production,dns,infrastructure"
    }
    "monitoring-agent" = {
      description = "Monitoring and metrics collection container"
      cpu_cores   = 1
      memory      = 768
      disk_size   = "10G"
      ip_address  = "192.168.1.171/24"
      tags        = "production,monitoring,infrastructure"
    }
  }
}

# Create Production LXC containers using the shared LXC module
module "production_lxc" {
  source = "../modules/lxc"  # 👈 Using shared LXC module

  for_each = local.production_lxc

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
  enable_nesting = true  # Allow Docker if needed
  privileged     = false # Security best practice

  # Startup Configuration
  start_on_create = true
  start_on_boot   = true

  # Organization
  tags = each.value.tags
}