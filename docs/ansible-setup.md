# Ansible Configuration Management Setup

This guide walks you through setting up Ansible for managing VUV lab infrastructure VMs. **If you're new to Ansible** - don't worry, we provide step-by-step instructions with validation at each stage.

## How to Use This Guide

This Ansible setup guide is part of the complete VUV Lab Infrastructure deployment process:

1. **[Getting Started](getting-started.md)** - Overview and prerequisites ✅
2. **[Proxmox Setup](proxmox-setup.md)** - Hypervisor configuration ✅  
3. **[Terraform Configuration](terraform-configuration.md)** - Infrastructure provisioning ✅
4. **👉 Ansible Setup** - Configuration management (this guide)
5. **Service Deployment** - Deploy specific services (GNS3, monitoring, etc.)

> 💡 **Previous Step**: Ensure you have completed **[Terraform Configuration](terraform-configuration.md)** before proceeding. You need deployed VMs to configure with Ansible.

## Prerequisites

Before starting, verify you have completed previous steps:

- ✅ **[Proxmox VE configured](proxmox-setup.md)** with templates and API access
- ✅ **[Terraform working](terraform-configuration.md)** with successful VM deployments
- ✅ **SSH key pair generated** (`~/.ssh/proxmox_key` and `~/.ssh/proxmox_key.pub`)
- ✅ **VMs accessible** via SSH using initial user (e.g., `vuvadmin`)
- ✅ **Python 3 installed** on your management workstation

## Installation

### Ubuntu/Debian Workstation

```bash
# Update package list
sudo apt update

# Install Ansible
sudo apt install ansible -y

# Verify installation (should show version 2.15+)
ansible --version
```

### Windows with WSL2

```bash
# In WSL2 terminal
sudo apt update
sudo apt install ansible python3-pip -y

# Verify installation
ansible --version
```

### macOS

```bash
# Using Homebrew
brew install ansible

# Or using pip
pip3 install ansible

# Verify installation
ansible --version
```

### Windows with Chocolatey

```powershell
# In administrative PowerShell
choco install ansible -y

# Verify installation
ansible --version
```

## Project Structure

The Ansible configuration follows the project structure defined in **[Getting Started](getting-started.md#planned-directory-structure)**:

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   └── hosts               # Static inventory file
├── playbooks/
│   ├── bootstrap.yml       # Initial VM setup (creates 'lab' user)
│   ├── initial_setup.yml   # Basic connectivity tests
│   ├── system_updates.yml  # System maintenance
│   └── security_hardening.yml # Security configuration
├── roles/                  # Service-specific roles (future)
└── ssh_keys/              # Team SSH public keys
    └── README.md          # SSH key management guide
```

## SSH Key Management for Teams

### Standard SSH Key Setup

**Important**: All team members must use the **same key filename** for consistency.

Each team member should generate their SSH key with the standard name:

```bash
# Generate RSA key with standard filename (REQUIRED)
ssh-keygen -t rsa -b 4096 -C "firstname.lastname@vuv.hr" -f ~/.ssh/vuv-lab-key

# Set proper permissions
chmod 600 ~/.ssh/vuv-lab-key
chmod 644 ~/.ssh/vuv-lab-key.pub
```

### Multi-Team Member Workflow

The bootstrap process is **idempotent** and supports multiple team members:

#### **Scenario 1: First Team Member**
```bash
# Generate your key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/vuv-lab-key

# Run bootstrap (creates ansible user + deploys your key)
ansible-playbook -u ubuntu -kK playbooks/bootstrap.yml

# Use Ansible normally
ansible all -m ping
```

#### **Scenario 2: Additional Team Members**
```bash
# Generate your key (same filename!)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/vuv-lab-key

# Run bootstrap (adds your key to existing setup)
ansible-playbook -u ubuntu -kK playbooks/bootstrap.yml

# Use Ansible normally
ansible all -m ping
```

#### **Scenario 3: Someone Already Bootstrapped**
**✅ Always run bootstrap from your workstation!**

```bash
# Generate your key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/vuv-lab-key

# Run bootstrap anyway - it's safe!
ansible-playbook -u ubuntu -kK playbooks/bootstrap.yml
```

**Why this works:**
- ✅ **Idempotent** - Safe to run multiple times
- ✅ **Additive** - Adds your key without removing others
- ✅ **Simple** - No complex configuration needed

## Bootstrap Process

### Step 1: Prepare Your Environment

1. **Ensure SSH server is running on target VMs:**
   ```bash
   # On each VM (via console if needed):
   sudo apt update
   sudo apt install openssh-server -y
   sudo systemctl start ssh
   sudo systemctl enable ssh
   ```

2. **Navigate to the ansible directory:**
   ```bash
   cd /path/to/vuv-lab-infra/ansible
   ```

3. **Verify your SSH key exists:**
   ```bash
   ls -la ~/.ssh/vuv-lab-key*
   # Should show both vuv-lab-key and vuv-lab-key.pub
   ```

4. **Test initial VM connectivity** using credentials from **[Terraform setup](terraform-configuration.md)**:
   ```bash
   # Replace with your actual VM IP and initial user
   ssh ubuntu@192.168.1.100
   ```

### Step 2: Update Inventory with Your VMs

Edit `inventory/hosts.yml` with actual VM IPs from your Terraform deployment:

```yaml
# Management and Infrastructure VMs
[management]
dns-server ansible_host=192.168.1.10
traefik-proxy ansible_host=192.168.1.11

# Network Simulation
[gns3]
gns3-server ansible_host=192.168.1.20

# Monitoring Stack  
[monitoring]
prometheus ansible_host=192.168.1.30
grafana ansible_host=192.168.1.31

# Container Hosts
[docker_hosts]
docker-host-01 ansible_host=192.168.1.40

# Service Groups
[infrastructure:children]
management
monitoring

[services:children]
gns3
docker_hosts

# All lab VMs
[lab_vms:children]
infrastructure
services
```

> 💡 **Tip**: Get VM IPs from Terraform outputs: `cd ../terraform && terraform output`

### Step 3: Run Bootstrap Playbook

The bootstrap playbook creates the `ansible` user for automation:

```bash
# Run bootstrap with password authentication (connects as ubuntu, creates ansible user)
ansible-playbook -u ubuntu -kK playbooks/bootstrap.yml

# When prompted:
# SSH password: [ubuntu user password]
# BECOME password: [same password - for sudo]
```

**What the bootstrap does:**
- Creates `ansible` user with passwordless sudo access
- Deploys your SSH public key to the `ansible` user
- Configures proper SSH access permissions
- Validates the setup for Ansible management

### Step 4: Verify Bootstrap Success

Test the new `ansible` user connection:

```bash
# Test connectivity to all hosts (should work without passwords now)
ansible all -m ping

# Should return SUCCESS for all hosts
```

Expected output:
```
dns-server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
gns3-server | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

### Step 5: Test SSH Key Access

```bash
# Test direct SSH connection as ansible user
ssh ansible@192.168.1.10

# Should connect without password prompt
# Test sudo access:
sudo whoami  # Should return: root
exit
```

## Post-Bootstrap Configuration

### Complete Infrastructure Setup (Recommended)

Run all foundation playbooks with a single command:

```bash
# Complete VUV lab infrastructure foundation setup
ansible-playbook site.yml
```

This orchestrates:
1. **Initial setup** - Connectivity verification and essential tools
2. **System updates** - Package updates and automatic security updates  
3. **Security hardening** - Firewall, SSH security, and intrusion protection

### Individual Playbooks (When Needed)

For selective updates or troubleshooting:

```bash
# Test connectivity and install essential tools
ansible-playbook playbooks/initial_setup.yml

# Update systems and configure automatic updates
ansible-playbook playbooks/system_updates.yml

# Apply security hardening measures
ansible-playbook playbooks/security_hardening.yml
```

### What Gets Configured

**Essential Tools**: vim, htop, git, curl, wget, tree, net-tools, tcpdump, fail2ban, and more

**System Updates**: 
- Full package updates with `apt upgrade`
- Unattended security updates configured
- Time synchronization enabled

**Security Hardening**:
- UFW firewall (SSH allowed, deny incoming by default)
- SSH key-based authentication only (no passwords)
- Root login disabled  
- fail2ban protection against brute force
- Configurable unnecessary services disabled (`avahi-daemon`, `cups`, `bluetooth`)

**University-Friendly**:
- No user access restrictions (staff can create lab users)
- Service-specific firewall rules preserved (safe for GNS3, DNS, etc.)
- Clean output without verbose status messages

## Common Commands Reference

### Inventory Management

```bash
# List all hosts in inventory
ansible-inventory --list

# Show inventory structure
ansible-inventory --graph

# Test connectivity to specific group
ansible gns3 -m ping

# Run commands on all hosts
ansible all -m shell -a "uptime"
```

### Playbook Execution

```bash
# Run with specific inventory file
ansible-playbook -i inventory/hosts playbooks/system_updates.yml

# Dry run (check what would change)
ansible-playbook --check playbooks/security_hardening.yml

# Run on specific hosts or groups
ansible-playbook --limit gns3 playbooks/initial_setup.yml
ansible-playbook --limit management playbooks/system_updates.yml

# Run with extra verbosity
ansible-playbook -v playbooks/bootstrap.yml
```

### System Information Gathering

```bash
# Gather all system facts
ansible all -m setup

# Check disk space on all hosts
ansible all -m shell -a "df -h"

# Check system load and uptime
ansible all -m shell -a "uptime"

# Check installed packages
ansible all -m shell -a "dpkg -l | grep -E '(docker|nginx|apache)'"
```

## Troubleshooting Common Issues

### SSH Connection Problems

**Problem**: `Connection refused` on port 22

**Cause**: SSH server not installed on target VM

**Solution**: Install OpenSSH server on the VM
```bash
# On the VM console (VirtualBox, Proxmox console, etc.)
sudo apt update
sudo apt install openssh-server -y
sudo systemctl start ssh
sudo systemctl enable ssh
```

**Problem**: `Permission denied (publickey)` 

**Solution**: Re-run bootstrap or check SSH key deployment
```bash
# Verify SSH key exists with correct name
ls -la ~/.ssh/vuv-lab-key*

# Test manual SSH connection
ssh ansible@your-vm-ip

# Re-run bootstrap if needed
ansible-playbook -u ubuntu -kK playbooks/bootstrap.yml
```

**Problem**: `Host key verification failed`

**Solution**: Clear SSH known hosts
```bash
# Remove old host key
ssh-keygen -R your-vm-ip

# Or disable host key checking temporarily
export ANSIBLE_HOST_KEY_CHECKING=False
```

### Bootstrap Issues

**Problem**: `Invalid/incorrect password` during bootstrap

**Cause**: Ansible trying to connect as wrong user

**Solution**: Explicitly specify initial user
```bash
# Always specify -u ubuntu for bootstrap
ansible-playbook -u ubuntu -kK playbooks/bootstrap.yml

# When prompted:
# SSH password: [ubuntu user password]  
# BECOME password: [same password]
```

**Problem**: `Missing sudo password` with ping command

**Cause**: ansible.cfg forcing become=True

**Solution**: Use working ansible.cfg (already fixed in our setup)
```bash
# Should work with clean ansible.cfg
ansible all -m ping
```

**Problem**: "ansible is not in the sudoers file"

**Solution**: Manually fix sudoers configuration
```bash
# SSH as ubuntu user and fix sudoers
ssh ubuntu@your-vm-ip
sudo visudo -f /etc/sudoers.d/ansible
# Add: ansible ALL=(ALL) NOPASSWD:ALL
```

### Inventory and Playbook Issues

**Problem**: `Could not match supplied host pattern`

**Solution**: Verify inventory syntax
```bash
# Check inventory syntax
ansible-inventory --list
ansible-inventory --graph

# Test specific group exists
ansible management --list-hosts
```

**Problem**: Playbook tasks fail with permission errors

**Solution**: Check privilege escalation
```bash
# Test become (sudo) access
ansible all -m shell -a "whoami" --become

# Check ansible.cfg become settings
grep -i become ansible.cfg
```

## Security Best Practices

### SSH Key Security

- **Generate unique keys** for lab infrastructure access
- **Use strong passphrases** on private keys
- **Store private keys securely** (never in version control)
- **Rotate keys regularly** (especially when staff changes)
- **Audit authorized_keys** periodically

### Access Management

- **Use `ansible` user only for automation** - create separate accounts for human access
- **Implement proper RBAC** for production environments
- **Log all administrative actions** via sudo logging
- **Network segmentation** between management and production networks

### Ansible Security

- **Encrypt sensitive variables** using ansible-vault
- **Use jump hosts** for network isolation
- **Implement proper inventory management** (separate dev/prod)
- **Regular security updates** via automated playbooks

## Next Steps

After successful Ansible setup, you can proceed with service deployment:

### Service-Specific Playbooks

- **GNS3 Server**: Network simulation platform deployment
- **DNS Server**: BIND configuration for name resolution
- **Monitoring Stack**: Prometheus and Grafana deployment
- **Docker Hosts**: Container platform configuration
- **Traefik Proxy**: Reverse proxy and load balancer

### Advanced Ansible Features

- **Ansible Vault**: Encrypt sensitive configuration data
- **Dynamic Inventory**: Auto-discover VMs from Proxmox
- **Roles Development**: Create reusable configuration components
- **CI/CD Integration**: Automate playbook execution

## Integration with Other Tools

### Terraform Integration

- **VM Provisioning**: VMs created via **[Terraform](terraform-configuration.md)**
- **Inventory Population**: Use Terraform outputs for Ansible inventory
- **Infrastructure Updates**: Coordinate Terraform and Ansible changes

### Proxmox Integration

- **Template Management**: Templates created in **[Proxmox setup](proxmox-setup.md)**
- **VM Lifecycle**: Ansible configures VMs provisioned from Proxmox
- **Backup Integration**: Ansible configures backup schedules

## Validation Checklist

- [ ] **Ansible installed** and version 2.15+ verified
- [ ] **SSH key generated** with standard name `~/.ssh/vuv-lab-key`
- [ ] **SSH server running** on all target VMs
- [ ] **Inventory updated** with actual VM IP addresses from Terraform
- [ ] **Bootstrap playbook completed** successfully for all VMs
- [ ] **`ansible all -m ping`** returns SUCCESS for all hosts
- [ ] **`ansible` user configured** with passwordless sudo access
- [ ] **Direct SSH access works**: `ssh ansible@vm-ip`
- [ ] **Foundation playbooks completed**: `ansible-playbook site.yml` runs successfully
- [ ] **All warnings resolved**: No Python interpreter or UFW parameter warnings
- [ ] **Clean output verified**: No verbose status messages cluttering output
- [ ] **Team members can run bootstrap** to add their keys

## Next Steps: Service Deployment

With the Ansible foundation complete, you can now deploy specific services:

### Ready for Service Deployment

**Next Phase**: **[Services Deployment Guide](services-deployment.md)**

Available services to deploy:
- **GNS3 Server** - Network simulation platform  
- **DNS Server** - BIND DNS infrastructure
- **Monitoring Stack** - Prometheus and Grafana
- **Docker Hosts** - Container platform
- **Traefik Proxy** - Reverse proxy and load balancer

### Service Deployment Pattern
Each service follows the same reliable pattern:
1. **Terraform provisions** the VM with appropriate resources
2. **Ansible configures** the service using roles and playbooks
3. **Service-specific firewall rules** are added to existing security
4. **Integration testing** verifies the service works correctly

## Reference Documentation

### Related Guides
- **[Getting Started](getting-started.md)** - Project overview and workflow
- **[Proxmox Setup](proxmox-setup.md)** - Hypervisor configuration
- **[Terraform Configuration](terraform-configuration.md)** - Infrastructure provisioning
- **[Services Deployment Guide](services-deployment.md)** - Deploy GNS3, DNS, monitoring, and other services

### Configuration Files
- `ansible/ansible.cfg` - Main Ansible configuration (ansible user, vuv-lab-key)
- `ansible/inventory/hosts.yml` - VM inventory definitions (YAML format)  
- `ansible/playbooks/bootstrap.yml` - Creates ansible user and deploys SSH keys
- `ansible/playbooks/initial_setup.yml` - Connectivity verification and basic tools
- `ansible/playbooks/system_updates.yml` - System maintenance and package updates
- `ansible/playbooks/security_hardening.yml` - Security configuration and hardening

### External Resources
- **[Ansible Documentation](https://docs.ansible.com/)** - Official Ansible docs
- **[Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)** - Configuration guidelines
- **[Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)** - Encrypt sensitive data