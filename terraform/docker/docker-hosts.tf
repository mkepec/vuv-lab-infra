# Docker Hosts Configuration - Using Shared VM Module
# This demonstrates how the same module creates different types of infrastructure

# Docker Host VMs Configuration Map
locals {
  docker_hosts = {
    "docker-host-1" = {
      description = "Primary Docker host for containerized services"
      cpu_cores   = 4
      memory      = 8192
      disk_size   = 60
      ip_address  = "192.168.1.140/24"
    }
    "docker-host-2" = {
      description = "Secondary Docker host for load balancing"
      cpu_cores   = 4
      memory      = 8192
      disk_size   = 60
      ip_address  = "192.168.1.141/24"
    }
  }
}

# Create Docker Host VMs using the shared VM module
module "docker_hosts" {
  source = "../modules/vm"  # 👈 Same shared module as GNS3 and test

  for_each = local.docker_hosts

  # VM Identity
  vm_name        = each.key
  vm_description = each.value.description

  # Proxmox Configuration
  target_node   = var.proxmox_node
  template_name = var.template_name

  # Resource Allocation - Optimized for containers
  cpu_cores = each.value.cpu_cores
  memory    = each.value.memory
  disk_size = each.value.disk_size

  # Network Configuration - Single Subnet
  ip_address = each.value.ip_address
  gateway    = var.network_gateway

  # Cloud-init Configuration
  ci_user         = "ubuntu"
  ssh_public_keys = var.ssh_public_key

  # Docker optimizations
  enable_agent = true  # For better resource monitoring
}