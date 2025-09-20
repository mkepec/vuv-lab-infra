# Test LXC Containers Configuration - Using Shared LXC Module
# Single Subnet Approach (192.168.1.x)

# Test LXC Configuration Map
locals {
  test_lxc = {
    "lab-test-lxc-1" = {
      description = "First test LXC container"
      cpu_cores   = 1
      memory      = 512
      disk_size   = "8G"
      # Static IP Configuration (comment out for DHCP)
      # ip_address  = "192.168.1.170/24"
      tags        = "test,development"
    }
    "lab-test-lxc-2" = {
      description = "Second test LXC container"
      cpu_cores   = 1
      memory      = 512
      disk_size   = "8G"
      # Static IP Configuration (comment out for DHCP)
      # ip_address  = "192.168.1.171/24"
      tags        = "test,development"
    }
  }
}

# Create Test LXC containers using the shared LXC module
module "test_lxc" {
  source = "../modules/lxc"  # 👈 Using shared LXC module

  for_each = local.test_lxc

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

  # Network Configuration - DHCP by default
  # Option 1: DHCP (default - automatic IP assignment)
  use_dhcp = true

  # Option 2: Static IP (uncomment and set ip_address in locals above)
  # use_dhcp   = false
  # ip_address = each.value.ip_address
  # gateway    = var.network_gateway

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