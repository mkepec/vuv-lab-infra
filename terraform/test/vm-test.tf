# Test VM Resource - Simple VM to verify Terraform and Proxmox integration
# Based on official terraform-provider-proxmox documentation

resource "proxmox_vm_qemu" "test_server" {
  name        = "test-vm-1"
  description = "Terraform test VM with cloud-init"
  target_node = var.proxmox_node
  
  # Clone from template
  clone = var.template_name
  
  # CPU configuration (using cpu block)
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }
  
  # Memory configuration
  memory = 2048
  
  # SCSI hardware controller
  scsihw = "virtio-scsi-pci"
  
  # Disk configuration using disks block (new syntax)
  disks {
    scsi {
      scsi0 {
        disk {
          size    = 20
          storage = "local-lvm"
        }
      }
    }
    ide {
      ide3 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }
  
  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  # Boot configuration
  boot = "order=scsi0"
  
  # Cloud-init configuration with static IP
  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.1.100/24,gw=192.168.1.1"
  
  # User configuration - simplified for testing
  ciuser     = "ubuntu"
  cipassword = "test123"  # Simple password for console testing
  sshkeys    = var.ssh_public_key
  
  # Enhanced SSH configuration via cloud-init
  #cicustom = "user=local:snippets/lab-ssh-config.yml"
  #cicustom = "user=local:snippets/simple-ssh-fix.yml"
  
  # Disable QEMU guest agent for now (Ubuntu cloud image doesn't have it installed)
  agent = 0
  
  # Console configuration for reliable access
  serial {
    id   = 0
    type = "socket"
  }
  
  vga {
    type = "serial0"
  }
}