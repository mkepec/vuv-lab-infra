# LXC Module Main Configuration - Production-Ready Proxmox LXC
# Single Subnet Approach - No VLAN Tagging

resource "proxmox_lxc" "container" {
  hostname    = var.container_name
  description = var.description
  target_node = var.target_node

  # LXC template configuration
  ostemplate = "local:vztmpl/${var.template_name}"

  # Resource allocation
  cores  = var.cpu_cores
  memory = var.memory
  swap   = var.swap

  # Root filesystem
  rootfs {
    storage = var.disk_storage
    size    = var.disk_size
  }

  # Network configuration - Single subnet, no VLAN tagging
  network {
    name   = "eth0"
    bridge = var.network_bridge
    ip     = var.ip_address
    gw     = var.gateway
    # Note: No 'tag' parameter - enforcing single flat network
  }

  # Container features
  features {
    nesting = var.enable_nesting
  }

  # SSH key configuration
  ssh_public_keys = var.ssh_public_keys

  # Startup configuration
  start  = var.start_on_create
  onboot = var.start_on_boot

  # Security configuration
  unprivileged = !var.privileged

  # Organization tags
  tags = var.tags
}