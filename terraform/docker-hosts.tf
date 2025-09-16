# Docker Host VMs for containerized services
# These VMs will run Docker Engine and host containerized applications

resource "proxmox_vm_qemu" "docker_host" {
  count       = var.docker_host_count
  name        = "docker-host-${count.index + 1}"
  description = "Docker Host for containerized services - VM ${count.index + 1}"
  target_node = var.proxmox_node
  
  # Clone from Ubuntu template
  clone      = var.template_name
  full_clone = true
  
  # CPU configuration optimized for containers
  cpu {
    cores   = var.docker_host_cores
    sockets = 1
    type    = "host"
  }
  
  # Memory for Docker workloads
  memory = var.docker_host_memory
  
  # SCSI hardware controller
  scsihw = "virtio-scsi-pci"
  
  # Disk configuration for Docker
  disks {
    scsi {
      scsi0 {
        disk {
          size    = 30  # 30GB for OS and Docker images
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
  ipconfig0 = "ip=${var.network_base}.${30 + count.index}/24,gw=${var.network_gateway}"
  
  # User configuration
  ciuser  = "ubuntu"
  sshkeys = var.ssh_public_key
  
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
  tags = "docker,containers,services"
}