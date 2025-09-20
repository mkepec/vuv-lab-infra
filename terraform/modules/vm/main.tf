# VM Module Main Configuration - Production-Ready Proxmox VM
# Single Subnet Approach - No VLAN Tagging

resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  description = var.vm_description
  target_node = var.target_node

  # Clone from template
  clone = var.template_name

  # CPU configuration
  cpu {
    cores   = var.cpu_cores
    sockets = var.cpu_sockets
    type    = "host"
  }

  # Memory configuration
  memory = var.memory

  # SCSI hardware controller
  scsihw = "virtio-scsi-pci"

  # Disk configuration using new disks block syntax
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.disk_size
          storage = var.disk_storage
        }
      }
    }
    ide {
      ide3 {
        cloudinit {
          storage = var.disk_storage
        }
      }
    }
  }

  # Network configuration - Single subnet, no VLAN tagging
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
    # Note: No 'tag' parameter - enforcing single flat network
  }

  # Boot configuration
  boot = "order=scsi0"

  # Cloud-init configuration with dynamic IP assignment
  os_type = "cloud-init"
  # Use DHCP if use_dhcp is true, otherwise use static IP configuration
  ipconfig0 = var.use_dhcp ? "ip=dhcp" : "ip=${var.ip_address},gw=${var.gateway}"

  # User configuration
  ciuser     = var.ci_user
  cipassword = var.ci_password != "" ? var.ci_password : null
  sshkeys    = var.ssh_public_keys

  # QEMU guest agent
  agent = var.enable_agent ? 1 : 0

  # Optional serial console for debugging
  dynamic "serial" {
    for_each = var.enable_serial_console ? [1] : []
    content {
      id   = 0
      type = "socket"
    }
  }

  dynamic "vga" {
    for_each = var.enable_serial_console ? [1] : []
    content {
      type = "serial0"
    }
  }
}