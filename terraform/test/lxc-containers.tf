# Utility LXC Containers for testing
# These containers will test LXC provisioning and basic networking

resource "proxmox_lxc" "test_containers" {
  count       = var.lxc_count
  hostname    = "test-lxc-${count.index + 1}"
  description = "Test LXC container ${count.index + 1} for utility services"
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
    ip     = "${var.network_base}.${110 + count.index}/24"
    gw     = var.network_gateway
  }
  
  # Container features
  features {
    nesting = true  # Allow Docker or nested containers if needed
  }
  
  # SSH key configuration
  ssh_public_keys = var.ssh_public_key
  
  # Start container immediately after creation
  start = true

  # Start container on boot
  onboot = true

  # Unprivileged container for security
  unprivileged = true
  
  # Tags for organization
  tags = "test,lxc,utility"
}