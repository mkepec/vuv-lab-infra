# Terraform Configuration for Proxmox

This document explains how to configure Terraform to work with your Proxmox VE environment for infrastructure provisioning using the **independent workspace** approach.

## Project Structure - Independent Workspaces

The Terraform configuration uses **independent folders** for different services. Each folder is a complete, self-contained Terraform workspace:

```
terraform/
├── README.md            # Entry point guide - START HERE
│
├── test/                # 👈 BEGINNER START - Simple test VM
│   ├── versions.tf      # Provider configuration
│   ├── variables.tf     # Test-specific variables  
│   ├── main.tf          # Test VM resource definition
│   ├── outputs.tf       # IP addresses, SSH commands
│   ├── terraform.tfvars.example  # Example configuration
│   └── .terraform/      # Terraform state (auto-created)
│
├── gns3/                # GNS3 server (future)
│   └── README.md        # Placeholder
│
├── docker/              # Docker host VMs (future)
│   └── README.md        # Placeholder  
│
└── lxc/                 # LXC containers (future)
    └── README.md        # Placeholder
```

**Key Benefits:**
- ✅ **Simple workflow**: `cd test && terraform apply` only affects test/
- ✅ **Safe isolation**: Cannot accidentally deploy everything
- ✅ **Independent state**: Each service has separate state files
- ✅ **Beginner-friendly**: Start with test/, learn incrementally

## Core Configuration Files - Test Workspace Example

### Provider Configuration (test/versions.tf)

**Purpose**: Defines which Terraform version and providers to use, plus provider connection settings.

```hcl
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
```

*Note: Provider configuration is **duplicated** in each workspace folder for independence.*

### Variable Definitions (test/variables.tf)

**Purpose**: Defines configurable input parameters for the test workspace. Only includes variables actually used.

```hcl
variable "proxmox_host" {
  description = "Proxmox VE hostname or IP address"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox VE node name"
  type        = string
}

variable "template_name" {
  description = "VM template name to clone from"
  type        = string
  default     = "ubuntu2404-cloud"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (paste your ~/.ssh/proxmox_key.pub content here)"
  type        = string
}
```

*Note: Test workspace uses minimal variables - only what's needed for a simple test VM.*

### Main Configuration (test/main.tf)

**Purpose**: Defines the actual infrastructure resources - in this case, a simple test VM.

```hcl
# Test VM Resource - Simple VM to verify Terraform and Proxmox integration
resource "proxmox_vm_qemu" "test_server" {
  count       = 1
  name        = "test-vm-${count.index + 1}"
  target_node = var.proxmox_node
  
  # Clone from template
  clone      = var.template_name
  full_clone = true
  
  # CPU configuration
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }
  
  # Memory configuration (2GB)
  memory = 2048
  
  # Disk configuration
  disk {
    slot    = "scsi0"
    storage = "local-lvm"
    type    = "disk"
    size    = "20G"
  }
  
  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  # Wait for template clone to complete
  clone_wait = 10
  
  # Cloud-init configuration for SSH access
  os_type   = "cloud-init"
  ipconfig0 = "ip=dhcp"      # Get IP from DHCP
  
  ciuser  = "ubuntu"         # Default user
  sshkeys = var.ssh_public_key
}
```

*Note: Test VM uses hardcoded values (2 CPU, 2GB RAM, 20GB disk) to keep it simple for beginners.*

### Output Definitions (test/outputs.tf)

**Purpose**: Defines useful information to display after deployment (IP addresses, SSH commands, etc.).

```hcl
# Output VM information for easy access
output "vm_info" {
  description = "Test VM information"
  value = {
    name = proxmox_vm_qemu.test_server[0].name
    vmid = proxmox_vm_qemu.test_server[0].vmid
    node = proxmox_vm_qemu.test_server[0].target_node
  }
}

# Output IP address once VM is running
output "vm_ip" {
  description = "Test VM IP address"
  value       = proxmox_vm_qemu.test_server[0].default_ipv4_address
}

# Output ready-to-use SSH command
output "ssh_command" {
  description = "SSH command to connect to test VM"
  value       = "ssh -i ~/.ssh/proxmox_key ubuntu@${proxmox_vm_qemu.test_server[0].default_ipv4_address}"
}
```

*Note: Outputs provide ready-to-use information for connecting to your test VM.*

## Configuration Examples

### Example Configuration (test/terraform.tfvars.example)

**Purpose**: Template showing exactly what values you need to configure for the test workspace.

```hcl
# Proxmox connection settings
# Copy this file to terraform.tfvars and fill in your values
proxmox_host = "192.168.1.91"         # Your Proxmox server IP
proxmox_node = "pve"                  # Your Proxmox node name

# API token (from Proxmox setup guide)
proxmox_api_token = "your-api-token-secret-here"

# VM template (created during Proxmox setup)
template_name = "ubuntu2404-cloud"

# SSH public key (paste content from ~/.ssh/proxmox_key.pub)
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... vuv-lab-proxmox"
```

*Note: Test workspace only requires 5 configuration values - much simpler than complex examples.*

### Production Configuration Example

```hcl
# Production settings with enhanced security
proxmox_host              = "proxmox.internal.company.com"
proxmox_tls_insecure      = false  # Use proper TLS certificates
proxmox_api_token_secret  = "secure-token-from-vault"
proxmox_node              = "pve-prod-01"

# Production VM specifications
vm_count         = 5
vm_name_prefix   = "prod-app"
vm_cores         = 4
vm_memory        = 8192
vm_disk_size     = "50G"
vm_storage       = "fast-ssd"

# Enhanced network configuration
network_bridge = "vmbr1"  # Production network
```

## Environment-Specific Configuration

### Development Environment

Create `environments/dev/terraform.tfvars`:

```hcl
# Development settings
vm_count         = 1
vm_cores         = 1
vm_memory        = 1024
vm_disk_size     = "10G"
vm_name_prefix   = "dev-test"
```

### Staging Environment

Create `environments/staging/terraform.tfvars`:

```hcl
# Staging settings
vm_count         = 2
vm_cores         = 2
vm_memory        = 4096
vm_disk_size     = "30G"
vm_name_prefix   = "staging-app"
```

## Advanced Configuration Options

### Custom Cloud-Init Configuration

```hcl
# Custom cloud-init with additional packages
resource "proxmox_vm_qemu" "lab_vm" {
  # ... other configuration ...
  
  # Advanced cloud-init
  cicustom = "user=local:snippets/user-data-${count.index}.yml"
  
  # Custom network configuration
  ipconfig0 = "ip=192.168.1.${100 + count.index}/24,gw=192.168.1.1"
  nameserver = "192.168.1.1"
}
```

### Multiple Network Interfaces

```hcl
resource "proxmox_vm_qemu" "multi_net_vm" {
  # ... basic configuration ...
  
  # Management network
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  # Application network
  network {
    model  = "virtio" 
    bridge = "vmbr1"
  }
  
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=10.0.1.10/24"
}
```

### Resource Pools

```hcl
# Create resource pool
resource "proxmox_pool" "lab_pool" {
  poolid  = "lab-resources"
  comment = "Laboratory VMs and resources"
}

# Assign VMs to pool
resource "proxmox_vm_qemu" "lab_vm" {
  # ... other configuration ...
  pool = proxmox_pool.lab_pool.poolid
}
```

## Terraform Workflow - Independent Workspaces

### Beginner Workflow (Test Workspace)

**Start with the test workspace to verify everything works:**

```bash
# Navigate to test workspace
cd terraform/test

# Initialize workspace (first time only)
terraform init

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan and deploy
terraform plan    # Review what will be created
terraform apply   # Deploy test VM

# Verify deployment
terraform output  # Show VM IP and SSH command

# Clean up when done
terraform destroy
```

### Working with Other Services

**Each service follows the same pattern:**

```bash
# For GNS3 (future)
cd terraform/gns3
terraform init
terraform apply

# For Docker hosts (future)  
cd terraform/docker
terraform init
terraform apply

# Each is completely independent!
```

### Common Commands (in any workspace)

```bash
# Show current state
terraform show

# List resources  
terraform state list

# Show outputs (IP addresses, etc.)
terraform output

# Validate configuration
terraform validate

# Format code nicely
terraform fmt
```

## Best Practices

### Security
- Store sensitive values in `terraform.tfvars` (excluded from git)
- Use environment variables for secrets: `TF_VAR_proxmox_api_token_secret`
- Enable proper TLS certificates in production
- Implement least-privilege access

### State Management
- Use remote state storage for team collaboration
- Enable state locking
- Regular state backups
- Version control for configuration files

### Resource Naming
- Use consistent naming conventions
- Include environment in resource names
- Use descriptive prefixes
- Implement resource tagging where possible

### Testing
- Always run `terraform plan` before apply
- Use separate environments for testing
- Implement automated validation
- Test destruction/recreation scenarios

## Troubleshooting

### Common Issues

**Provider Authentication Fails:**
```bash
# Check token format and permissions
curl -k -H 'Authorization: PVEAPIToken=terraform@pve!terraform-token=TOKEN' \
  https://proxmox-host:8006/api2/json/version
```

**Template Not Found:**
```bash
# Verify template exists
qm list 9001
# Check template name in Proxmox matches terraform configuration
```

**Resource Creation Fails:**
- Verify sufficient resources (CPU, memory, storage)
- Check node capacity and storage availability
- Ensure network bridge exists
- Validate VM ID ranges

### Debug Mode

Enable detailed logging:

```bash
export TF_LOG=DEBUG
terraform plan
```

## Integration with Other Tools

### Ansible Integration

```hcl
# Generate Ansible inventory
output "ansible_inventory" {
  value = {
    for vm in proxmox_vm_qemu.lab_vm :
    vm.name => {
      ansible_host = vm.default_ipv4_address
      ansible_user = var.vm_user
      ansible_ssh_private_key_file = "~/.ssh/proxmox_key"
    }
  }
}
```

### Monitoring Integration

Add monitoring tags and configurations for integration with monitoring systems.

## Next Steps

✅ **Terraform configuration is complete!**

### Continue with the Setup Process

1. **Return to Getting Started**: Go back to [Getting Started Guide](getting-started.md#step-4-first-deployment) to continue with Step 4: First Deployment
2. **Validation**: Use [Validation & Testing Guide](validation-testing.md) for comprehensive testing procedures

### What You've Accomplished

- ✅ Complete Terraform configuration with provider setup
- ✅ Variable definitions and example configurations
- ✅ Best practices for security and state management
- ✅ Ready for infrastructure deployment

### Guide Navigation

- ⬅️ **Previous**: [Workstation Setup Guide](workstation-setup.md) (tool installation and configuration)
- ➡️ **Next**: [Validation & Testing Guide](validation-testing.md) (comprehensive testing)
- 📋 **Alternative**: Continue with [Getting Started Step 4](getting-started.md#step-4-first-deployment) (deploy test VM)

---

### Advanced Topics

After successful VM deployment:

1. Configure post-deployment automation (Ansible)
2. Set up monitoring and logging
3. Implement backup procedures
4. Add additional services (LXC containers, networking)
5. Integrate with CI/CD pipelines