# VUV Lab Infrastructure - Terraform Configuration

This directory contains Terraform configurations for provisioning VUV laboratory infrastructure on Proxmox VE.

## Overview

The Terraform configuration creates a complete laboratory environment with:

- **GNS3 Servers**: High-performance VMs for network simulation
- **Docker Hosts**: VMs optimized for containerized services  
- **Utility Containers**: Lightweight LXC containers for DNS, NTP, monitoring

## Quick Start

### Prerequisites

1. **Proxmox VE setup completed** (see `docs/proxmox-setup.md`)
2. **Workstation configured** (see `docs/workstation-setup.md`)
3. **SSH key pair created** (`~/.ssh/proxmox_key`)

### Deployment Steps

```bash
# 1. Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Deploy infrastructure
terraform apply

# 5. View infrastructure details
terraform output
```

## Configuration Files

### Core Files

- **`main.tf`**: Provider configuration
- **`variables.tf`**: All variable definitions
- **`outputs.tf`**: Infrastructure outputs and Ansible inventory
- **`terraform.tfvars.example`**: Example configuration

### Resource Files

- **`gns3-servers.tf`**: GNS3 server VMs
- **`docker-hosts.tf`**: Docker host VMs
- **`utility-containers.tf`**: Utility LXC containers

### Testing

- **`test/`**: Minimal test configuration for validation

## Resource Details

### GNS3 Servers

**Purpose**: Network simulation and topology testing
**Configuration**:
- **CPU**: 4 cores (configurable)
- **Memory**: 4096MB (configurable)  
- **Disk**: 50GB for GNS3 images
- **IP Range**: 192.168.1.20-29

**Access**:
```bash
ssh -i ~/.ssh/proxmox_key ubuntu@192.168.1.20  # gns3-server-1
```

### Docker Hosts

**Purpose**: Containerized application hosting
**Configuration**:
- **CPU**: 2 cores (configurable)
- **Memory**: 2048MB (configurable)
- **Disk**: 30GB for containers
- **IP Range**: 192.168.1.30-39

**Access**:
```bash
ssh -i ~/.ssh/proxmox_key ubuntu@192.168.1.30  # docker-host-1
ssh -i ~/.ssh/proxmox_key ubuntu@192.168.1.31  # docker-host-2
```

### Utility Containers

**Purpose**: Lightweight services (DNS, NTP, monitoring)
**Configuration**:
- **CPU**: 1 core
- **Memory**: 512MB
- **Disk**: 8GB
- **IP Range**: 192.168.1.40-49

**Access**:
```bash
ssh -i ~/.ssh/proxmox_key root@192.168.1.40  # utility-1
ssh -i ~/.ssh/proxmox_key root@192.168.1.41  # utility-2
ssh -i ~/.ssh/proxmox_key root@192.168.1.42  # utility-3
```

## Scaling Configuration

Adjust resource counts in `terraform.tfvars`:

```hcl
# Scale GNS3 servers
gns3_server_count = 2           # Creates gns3-server-1, gns3-server-2

# Scale Docker hosts  
docker_host_count = 3           # Creates docker-host-1, docker-host-2, docker-host-3

# Scale utility containers
utility_lxc_count = 5           # Creates utility-1 through utility-5
```

## Network Configuration

**Static IP Assignment**:
- Base network: `192.168.1.0/24`
- Gateway: `192.168.1.1`
- GNS3 servers: `.20-.29`
- Docker hosts: `.30-.39`
- Utility containers: `.40-.49`

**Customization**:
```hcl
# Change network base
network_base = "10.0.1"         # Changes to 10.0.1.x network
network_gateway = "10.0.1.1"    # Corresponding gateway
```

## Resource Requirements

### Minimum Proxmox Host Specs
- **CPU**: Intel Xeon or equivalent with VT-x/AMD-V
- **Memory**: 16GB+ (recommended 32GB+)
- **Storage**: 500GB+ available space
- **Network**: Gigabit connection

### Default Resource Allocation
- **Total VMs**: 3 (1 GNS3 + 2 Docker)
- **Total Containers**: 3 utility containers
- **Total CPU**: 8 cores allocated
- **Total Memory**: 8.5GB allocated
- **Total Storage**: ~140GB allocated

## Ansible Integration

Terraform automatically generates Ansible inventory information:

```bash
# View Ansible inventory
terraform output ansible_inventory

# Use with Ansible
terraform output -json ansible_inventory > ../ansible/inventory.json
```

## Common Operations

### Add More Resources

```bash
# Edit terraform.tfvars to increase counts
nano terraform.tfvars

# Apply changes
terraform plan
terraform apply
```

### Remove Resources

```bash
# Edit terraform.tfvars to decrease counts
nano terraform.tfvars

# Apply changes (will destroy excess resources)
terraform plan
terraform apply
```

### Destroy All Infrastructure

```bash
terraform destroy
```

### Check Resource Status

```bash
# Show all resources
terraform show

# Show specific outputs
terraform output gns3_servers
terraform output docker_hosts
terraform output utility_containers
```

## Testing

The `test/` directory contains a minimal configuration for validation:

```bash
cd test/
terraform init
terraform plan
terraform apply
```

This creates a single test VM to verify:
- ✅ Proxmox connectivity
- ✅ Template cloning
- ✅ Network configuration
- ✅ SSH access

## Troubleshooting

### Common Issues

**1. Template Not Found**
```bash
# Check available templates on Proxmox
qm list

# Verify template name in terraform.tfvars
template_name = "ubuntu2404-cloud"
```

**2. LXC Template Missing**
```bash
# Download LXC templates on Proxmox
pveam update
pveam available | grep ubuntu
pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```

**3. IP Address Conflicts**
```bash
# Check network range doesn't conflict
ping 192.168.1.20-49

# Adjust network_base if needed
network_base = "192.168.2"
```

**4. SSH Connection Failed**
```bash
# Verify SSH key exists
ls -la ~/.ssh/proxmox_key*

# Test SSH manually
ssh -i ~/.ssh/proxmox_key ubuntu@<vm-ip>
```

### Validation Commands

```bash
# Verify Proxmox API access
curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform-token=<token>" \\
  https://<proxmox-ip>:8006/api2/json/version

# Check Terraform configuration
terraform validate

# Test without applying
terraform plan
```

## Next Steps

After successful deployment:

1. **Configure Ansible**: Use output inventory for configuration management
2. **Install Services**: 
   - GNS3 Server on GNS3 VMs
   - Docker Engine on Docker hosts
   - Utility services on LXC containers
3. **Set up Monitoring**: Deploy monitoring stack
4. **Configure Networking**: Set up advanced network topologies

## Security Considerations

- SSH keys used for all access (no passwords)
- LXC containers run unprivileged 
- Network segmentation available via VLANs
- Regular security updates via Ansible

---

For detailed setup instructions, see:
- [Getting Started Guide](../docs/getting-started.md)
- [Proxmox Setup](../docs/proxmox-setup.md)
- [Workstation Setup](../docs/workstation-setup.md)