# Test VMs Configuration - Using Shared VM Module
# Single Subnet Approach (192.168.1.x)

# Test VM Configuration Map
locals {
  test_vms = {
    "lab-test-vm-1" = {
      description = "Test VM for development and testing"
      cpu_cores   = 2
      memory      = 2048
      disk_size   = 20
      # Static IP Configuration (comment out for DHCP)
      # ip_address  = "192.168.1.110/24"
    }
    # Uncomment for second test VM
    # "lab-test-vm-2" = {
    #   description = "Second test VM"
    #   cpu_cores   = 1
    #   memory      = 1024
    #   disk_size   = 15
    #   # Static IP Configuration (comment out for DHCP)
    #   # ip_address  = "192.168.1.111/24"
    # }
  }
}

# Create Test VMs using the shared VM module
module "test_vms" {
  source = "../modules/vm"

  for_each = local.test_vms

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

  # Enable guest agent and serial console for better management
  enable_agent          = true
  enable_serial_console = true
}