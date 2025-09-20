# Production VMs Configuration - Using VM Module
# Single Subnet Approach (192.168.1.x)

# Production VM Configuration Map
locals {
  production_vms = {
    "lab-vm-1" = {
      description = "Lab VM for student workspaces"
      cpu_cores   = 2
      memory      = 2048
      disk_size   = 25
      # Static IP Configuration (comment out for DHCP)
      # ip_address  = "192.168.1.110/24"
    }
    "service-vm-1" = {
      description = "Service VM for infrastructure services"
      cpu_cores   = 2
      memory      = 4096
      disk_size   = 30
      # Static IP Configuration (comment out for DHCP)
      # ip_address  = "192.168.1.120/24"
    }
  }
}

# Create Production VMs using the shared VM module
module "production_vms" {
  source = "../modules/vm"

  for_each = local.production_vms

  # VM Identity
  vm_name        = each.key
  vm_description = each.value.description

  # Proxmox Configuration
  target_node   = var.proxmox_node
  template_name = var.template_name

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

  # Cloud-init Configuration
  ci_user         = "ubuntu"
  ci_password     = var.vm_password
  ssh_public_keys = var.ssh_public_key

  # Enable serial console for debugging
  enable_serial_console = true
  enable_agent         = false
}