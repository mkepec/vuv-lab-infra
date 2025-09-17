# GNS3 Server Configuration - Using Shared VM Module
# This demonstrates reusability of the shared modules/vm module

# GNS3 Server VM Configuration
module "gns3_server" {
  source = "../modules/vm"  # 👈 Using shared VM module

  # VM Identity
  vm_name        = "gns3-server"
  vm_description = "GNS3 network simulation server"

  # Proxmox Configuration
  target_node   = var.proxmox_node
  template_name = var.template_name

  # Resource Allocation - Higher specs for GNS3
  cpu_cores = 4          # More CPU for network simulations
  memory    = 8192       # 8GB RAM for complex topologies
  disk_size = 50         # Larger disk for projects and images

  # Network Configuration - Single Subnet
  ip_address = "192.168.1.130/24"  # Dedicated IP for GNS3
  gateway    = var.network_gateway

  # Cloud-init Configuration
  ci_user         = "ubuntu"
  ssh_public_keys = var.ssh_public_key

  # Enable for GNS3 debugging
  enable_serial_console = true
  enable_agent         = true  # Enable for better VM management
}

# Optional: Additional GNS3 client VM
module "gns3_client" {
  source = "../modules/vm"  # 👈 Same shared module, different config

  # VM Identity
  vm_name        = "gns3-client"
  vm_description = "GNS3 client for remote access"

  # Proxmox Configuration
  target_node   = var.proxmox_node
  template_name = var.template_name

  # Resource Allocation - Standard specs for client
  cpu_cores = 2
  memory    = 4096
  disk_size = 25

  # Network Configuration
  ip_address = "192.168.1.131/24"
  gateway    = var.network_gateway

  # Cloud-init Configuration
  ci_user         = "ubuntu"
  ssh_public_keys = var.ssh_public_key

  enable_serial_console = true
}