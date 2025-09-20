# Terraform Configuration for Proxmox

This document explains how to configure Terraform to work with your Proxmox VE environment for infrastructure provisioning using the **independent workspace** approach.

## Project Structure - Shared Modules with Independent Workspaces

The Terraform configuration uses **shared modules** with **independent environment folders**. This provides maximum reusability while maintaining environment isolation:

```
terraform/
├── README.md                    # Entry point guide - START HERE
│
├── modules/                     # 🔄 SHARED REUSABLE MODULES
│   ├── vm/                      # Production-ready VM module
│   │   ├── variables.tf         # VM configuration parameters
│   │   ├── main.tf             # VM resource definition
│   │   ├── outputs.tf          # VM information outputs
│   │   └── versions.tf         # Provider requirements
│   └── lxc/                     # Production-ready LXC module
│       ├── variables.tf         # LXC configuration parameters
│       ├── main.tf             # LXC resource definition
│       ├── outputs.tf          # LXC information outputs
│       └── versions.tf         # Provider requirements
│
├── test/                        # 🧪 TEST ENVIRONMENT
│   ├── production-vms.tf        # Uses ../modules/vm
│   ├── test-lxc.tf             # Uses ../modules/lxc
│   ├── vm-test.tf              # Legacy test VM (can be removed)
│   ├── variables.tf            # Environment variables
│   ├── outputs.tf              # Environment outputs
│   ├── terraform.tfvars        # Environment configuration
│   └── .terraform/             # Environment state
│
├── gns3/                        # 🌐 GNS3 ENVIRONMENT
│   ├── gns3-server.tf          # Uses ../modules/vm
│   ├── variables.tf            # GNS3-specific variables
│   ├── outputs.tf              # GNS3 outputs
│   └── terraform.tfvars        # GNS3 configuration
│
├── docker/                      # 🐳 DOCKER ENVIRONMENT
│   ├── docker-hosts.tf         # Uses ../modules/vm
│   ├── variables.tf            # Docker-specific variables
│   ├── outputs.tf              # Docker outputs
│   └── terraform.tfvars        # Docker configuration
│
└── lxc/                         # 📦 LXC ENVIRONMENT
    ├── utility-containers.tf    # Uses ../modules/lxc
    ├── variables.tf             # LXC-specific variables
    ├── outputs.tf               # LXC outputs
    └── terraform.tfvars         # LXC configuration
```

**Key Benefits:**
- ✅ **Module Reusability**: One module, multiple environments
- ✅ **Environment Isolation**: Independent state files prevent accidents
- ✅ **Easy Maintenance**: Update module once, affects all environments
- ✅ **Scalable Architecture**: Add new environments easily
- ✅ **Production Ready**: Follows Terraform best practices

## Shared Modules Architecture

### Module Design Philosophy

Each module in `terraform/modules/` is designed to be:
- **Reusable**: Works across all environments (test, production, etc.)
- **Configurable**: Flexible parameters for different use cases
- **Single Purpose**: VM module for VMs, LXC module for containers
- **Well-Documented**: Clear variable descriptions and examples

### VM Module (`terraform/modules/vm/`)

**Purpose**: Creates Proxmox VMs with consistent configuration and single subnet networking.

**Key Features**:
- Flexible resource allocation (CPU, memory, disk)
- Cloud-init integration with SSH keys
- Single subnet networking (192.168.1.x)
- Serial console support for debugging
- Comprehensive outputs for monitoring

**Usage Example**:
```hcl
module "my_vm" {
  source = "../modules/vm"

  # Identity
  vm_name        = "web-server"
  vm_description = "Web application server"

  # Resources
  cpu_cores = 2
  memory    = 4096
  disk_size = 30

  # Network (single subnet)
  ip_address = "192.168.1.150/24"
  gateway    = "192.168.1.1"

  # Proxmox
  target_node   = var.proxmox_node
  template_name = var.template_name

  # Authentication
  ssh_public_keys = var.ssh_public_key
}
```

### LXC Module (`terraform/modules/lxc/`)

**Purpose**: Creates Proxmox LXC containers with consistent configuration and automatic startup.

**Key Features**:
- Lightweight containerization
- Automatic startup (`start = true`)
- Template-based deployment
- Resource limits and quotas
- Network configuration for single subnet

**Usage Example**:
```hcl
module "my_container" {
  source = "../modules/lxc"

  # Identity
  container_name = "dns-server"
  description    = "BIND DNS server container"

  # Resources
  cpu_cores = 1
  memory    = 512
  disk_size = 8

  # Network (single subnet)
  ip_address = "192.168.1.160/24"
  gateway    = "192.168.1.1"

  # LXC Configuration
  template_name = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  target_node   = var.proxmox_node

  # Authentication
  ssh_public_keys = var.ssh_public_key
}
```

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

## Network Configuration Strategy

### Current Implementation: Single Subnet Approach

The VUV lab currently uses a **single flat network (192.168.1.x)** for all resources to minimize complexity and avoid dependencies on university network equipment VLAN capabilities.

```hcl
# Current single subnet configuration in variables.tf
variable "network_base" {
  description = "Base network for all resources (e.g., 192.168.1)"
  type        = string
  default     = "192.168.1"
}

variable "network_gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.1.1"
}
```

**Benefits of current approach:**
- ✅ **Simple deployment** - No external network dependencies
- ✅ **Immediate functionality** - All services can communicate directly
- ✅ **Easy troubleshooting** - Single broadcast domain
- ✅ **University IT independence** - No switch configuration required

**Typical IP allocation:**
```
192.168.1.1-50      - Infrastructure (gateway, DNS, etc.)
192.168.1.51-100    - Service VMs (GNS3, Grafana, etc.)
192.168.1.101-150   - LXC containers (utilities, microservices)
192.168.1.151-200   - Lab VMs (student workspaces)
```

### IP Assignment Options

The Terraform modules support both **DHCP** and **static IP** assignment. You can choose the approach that best fits your network setup:

#### Option 1: DHCP Assignment (Default)

**Recommended for initial setup and testing.**

```hcl
# In production-vms.tf and production-lxc.tf
module "production_vms" {
  # ... other configuration ...

  # DHCP configuration
  use_dhcp = true  # Default: automatic IP assignment
}
```

**Benefits:**
- ✅ **Automatic IP management** - No manual IP conflict resolution
- ✅ **Easier setup** - Works immediately with most networks
- ✅ **Dynamic adaptation** - VMs get valid IPs from existing DHCP server
- ✅ **DHCP reservations** - Router can assign consistent IPs by MAC address

**Usage:**
- Ensure DHCP server is running on your network (router/firewall)
- VMs and LXC containers will request IPs automatically
- Check Proxmox console or DHCP server logs for assigned IPs
- Use DHCP reservations for predictable IP assignments

#### Option 2: Static IP Assignment

**Recommended for production deployment with known network layout.**

```hcl
# In production-vms.tf - uncomment ip_address in locals
locals {
  production_vms = {
    "lab-vm-1" = {
      # ... other config ...
      ip_address = "192.168.1.110/24"  # Uncomment this line
    }
  }
}

# In module configuration
module "production_vms" {
  # ... other configuration ...

  # Static IP configuration
  use_dhcp   = false
  ip_address = each.value.ip_address
  gateway    = var.network_gateway
}
```

**Benefits:**
- ✅ **Predictable networking** - Known IP addresses for each service
- ✅ **DNS planning** - Can pre-configure DNS records
- ✅ **Service integration** - Other services can reference known IPs
- ✅ **Documentation alignment** - IP addresses match planned architecture

**Usage:**
1. Edit `production-vms.tf` and `production-lxc.tf`
2. Uncomment `ip_address` lines in the `locals` blocks
3. Set `use_dhcp = false` in module configurations
4. Uncomment static IP parameters in module calls
5. Ensure no IP conflicts with existing network devices

#### Switching Between Methods

To **switch from DHCP to static IP**:
```bash
# 1. Edit configuration files
vim terraform/test/production-vms.tf  # Uncomment ip_address lines
vim terraform/test/production-lxc.tf  # Set use_dhcp = false

# 2. Apply changes
terraform plan   # Review changes
terraform apply  # Apply IP configuration changes
```

To **switch from static IP to DHCP**:
```bash
# 1. Edit configuration files
vim terraform/test/production-vms.tf  # Comment ip_address lines
vim terraform/test/production-lxc.tf  # Set use_dhcp = true

# 2. Apply changes
terraform plan   # Review changes
terraform apply  # Apply IP configuration changes
```

### Future Enhancement: VLAN Segmentation

> **📋 FUTURE IMPROVEMENT**: VLAN-based network isolation can be implemented as an enhancement when university network infrastructure capabilities are confirmed.

**Planned VLAN topology for future implementation:**

```hcl
# Future VLAN configuration example
variable "vlan_management" {
  description = "VLAN ID for management network (10.0.10.x/24)"
  type        = number
  default     = 10
}

variable "vlan_service" {
  description = "VLAN ID for service network (10.0.20.x/24)"
  type        = number
  default     = 20
}

variable "vlan_lab" {
  description = "VLAN ID for lab network (10.0.30.x/24)"
  type        = number
  default     = 30
}
```

**Network segmentation plan:**
- **Management VLAN (10)**: 10.0.10.x/24 - Infrastructure services (DNS, monitoring, Proxmox management)
- **Service VLAN (20)**: 10.0.20.x/24 - Application services (GNS3, Traefik, Docker hosts)
- **Lab VLAN (30)**: 10.0.30.x/24 - Student workstations and lab activities

**Prerequisites for VLAN implementation:**
- ✅ University switch must support 802.1Q VLAN tagging
- ✅ Inter-VLAN routing capability on network equipment
- ✅ Trunk port configuration to Proxmox server
- ✅ DHCP/DNS updates for multiple subnets
- ✅ Coordination with university IT department

**Migration path from single subnet to VLANs:**
1. **Assessment Phase**: Confirm university network equipment capabilities
2. **Coordination Phase**: Work with university IT for switch configuration
3. **Implementation Phase**: Update Terraform configurations to include VLAN tagging
4. **Testing Phase**: Validate inter-VLAN routing and service accessibility
5. **Cutover Phase**: Migrate services incrementally to maintain uptime

**Example VLAN-enabled resource configuration:**
```hcl
# Future VLAN implementation example
resource "proxmox_vm_qemu" "service_vm" {
  # ... basic VM configuration ...

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = var.vlan_service    # VLAN tagging
  }

  ipconfig0 = "ip=${cidrhost(var.service_network_cidr, 10)}/24,gw=${var.service_gateway}"
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

## Shared Module Workflow

### Development Workflow with Shared Modules

**1. Working with Multiple Environments**

Each environment is completely independent, but uses the same shared modules:

```bash
# Test Environment - Development and validation
cd terraform/test
terraform init      # Install shared modules
terraform apply     # Deploy test infrastructure

# GNS3 Environment - Network simulation
cd terraform/gns3
terraform init      # Install same shared modules
terraform apply     # Deploy GNS3 infrastructure

# Docker Environment - Container hosts
cd terraform/docker
terraform init      # Install same shared modules
terraform apply     # Deploy Docker infrastructure

# LXC Environment - Utility containers
cd terraform/lxc
terraform init      # Install same shared modules
terraform apply     # Deploy LXC infrastructure
```

**2. Module Updates**

When you update a shared module, all environments can use the new version:

```bash
# Update VM module (example: add new feature)
vim terraform/modules/vm/main.tf

# Apply updates to test environment first
cd terraform/test
terraform init      # Refresh module
terraform plan      # Review changes
terraform apply     # Test the update

# Deploy to other environments when ready
cd terraform/gns3
terraform init && terraform apply

cd terraform/docker
terraform init && terraform apply
```

**3. Environment-Specific Configuration**

Each environment has its own `terraform.tfvars` for different configurations:

```bash
# Test Environment (terraform/test/terraform.tfvars)
proxmox_host = "192.168.1.100"
proxmox_node = "pve"
# ... test-specific settings

# Production GNS3 (terraform/gns3/terraform.tfvars)
proxmox_host = "192.168.1.100"
proxmox_node = "pve"
# ... GNS3-specific settings with higher resources
```

**4. Safe Deployment Strategy**

```bash
# 1. Always test first
cd terraform/test
terraform plan && terraform apply

# 2. Deploy to staging/development environments
cd terraform/gns3
terraform plan && terraform apply

# 3. Deploy to production last
cd terraform/docker
terraform plan && terraform apply
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