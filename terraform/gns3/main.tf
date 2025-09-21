# GNS3 Server VM Configuration
# This creates a high-performance VM for GNS3 network simulation

terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_host}:8006/api2/json"
  pm_api_token_id     = "terraform@pve!terraform-token"
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "gns3_server" {
  count       = var.gns3_server_count
  name        = "gns3-server-${count.index + 1}"
  description = "GNS3 Server for network simulation - VM ${count.index + 1}"
  target_node = var.proxmox_node
  
  # Clone from Ubuntu template
  clone      = var.template_name
  full_clone = true
  
  # Higher CPU configuration for network simulation
  cpu {
    cores   = var.gns3_server_cores
    sockets = 1
    type    = "host"
  }
  
  # Higher memory for GNS3 workloads
  memory = var.gns3_server_memory
  
  # SCSI hardware controller
  scsihw = "virtio-scsi-pci"
  
  # Larger disk for GNS3 images and projects
  disks {
    scsi {
      scsi0 {
        disk {
          size    = 50  # 50GB for GNS3 images
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
  ipconfig0 = "ip=${var.network_base}.${20 + count.index}/24,gw=${var.network_gateway}"
  
  # User configuration
  ciuser    = "ubuntu"
  cipasswd  = "password123"  # Console login password
  sshkeys   = var.ssh_public_key
  
  # Enable QEMU guest agent for better management
  agent = 1
  
  # Console configuration
  serial {
    id   = 0
    type = "socket"
  }
  
  vga {
    type = "serial0"
  }
  
  # Tags for organization
  tags = "gns3,network,simulation"
}