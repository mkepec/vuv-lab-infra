# Utility LXC Containers for lightweight services
# These containers will run DNS, NTP, monitoring, and other utility services

resource "proxmox_lxc" "utility_services" {
  count       = var.utility_lxc_count
  hostname    = "utility-${count.index + 1}"
  description = "Utility container for lightweight services - LXC ${count.index + 1}"
  target_node = var.proxmox_node
  
  # LXC template configuration
  ostemplate = "local:vztmpl/${var.lxc_template}"
  
  # Resource allocation for lightweight services
  cores  = 1
  memory = 512
  swap   = 512
  
  # Root filesystem
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }
  
  # Network configuration with static IP
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.network_base}.${40 + count.index}/24"
    gw     = var.network_gateway
  }
  
  # Container features
  features {
    nesting = true  # Allow Docker or nested containers if needed
  }
  
  # SSH key configuration
  ssh_public_keys = var.ssh_public_key
  
  # Start container on boot
  onboot = true
  
  # Unprivileged container for security
  unprivileged = true
  
  # Tags for organization
  tags = "utility,lxc,services"
}