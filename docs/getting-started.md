# Getting Started with VUV Lab Infrastructure

This guide will walk you through setting up the VUV laboratory infrastructure from scratch using Terraform and Proxmox VE. **Don't worry if you're new to these tools** - we provide detailed step-by-step instructions with validation at each stage.

## How to Use This Guide

This getting-started guide provides an **overview of the process** with links to detailed guides for each step. Here's how to approach it:

- **New to Proxmox/Terraform?** Follow each section and use the **detailed guides** linked throughout
- **Experienced user?** Use this as a quick reference and checklist
- **Something not working?** Each detailed guide has comprehensive troubleshooting sections

> 💡 **Tip**: Don't try to rush through this. Each step has validation procedures to ensure everything works before moving forward.

## Prerequisites

Before starting, ensure you have:

- **Fresh Proxmox VE 9.x installation** on your Dell PowerEdge R530
- **Administrative access** to the Proxmox web interface  
- **Network connectivity** between your workstation and Proxmox host
- **Basic understanding** of virtualization concepts (helpful but not required)

> ℹ️ **New to virtualization?** Don't worry! The detailed guides explain concepts as we go.

## Process Overview

Here's the complete infrastructure deployment workflow:

### Phase 1: Infrastructure Foundation
1. **[Prepare Proxmox VE](#step-1-prepare-proxmox-ve)** - Set up secure access for Terraform
2. **[Set up your workstation](#step-2-workstation-setup)** - Install and configure required tools
3. **[Configure Terraform](#step-3-terraform-configuration)** - Create infrastructure code
4. **[Deploy and test](#step-4-first-deployment)** - Verify infrastructure works end-to-end

### Phase 2: Configuration Management
5. **[Configure VMs with Ansible](#step-5-ansible-configuration-management)** - Set up automated configuration management
6. **[Validation](#validation-checklist)** - Comprehensive testing before service deployment

### Phase 3: Service Deployment
7. **[Deploy Services](services-deployment.md)** - GNS3, monitoring, DNS, and other lab services

**Expected time**: 2-3 hours for complete setup (Phase 1-2)

> 💡 **Note**: This guide covers **Phase 1-2** (infrastructure + configuration management). Service deployment guides are separate.

## Step 1: Prepare Proxmox VE

This step configures Proxmox VE with a dedicated user, secure authentication, and VM template for Terraform.

> 📖 **Detailed Guide**: For complete instructions with troubleshooting, see **[Proxmox Setup Guide](proxmox-setup.md)**

### 1.1 Quick Overview

You'll need to:
1. **Access** Proxmox web interface at `https://your-proxmox-ip:8006`
2. **Create** a dedicated terraform user with proper permissions  
3. **Generate** an API token for secure authentication
4. **Build** an Ubuntu 24.04 VM template for cloning
5. **Test** that everything works

### 1.2 Key Commands

Here are the essential commands (run these in Proxmox shell):

```bash
# Create role and user
pveum role add TerraformProv -privs "VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Migrate,VM.PowerMgmt,VM.Snapshot,Datastore.AllocateSpace,Datastore.Audit,Pool.Allocate,Pool.Audit,SDN.Use,Sys.Audit,Sys.Console"
pveum user add terraform@pve --password "SecurePassword123!"
pveum aclmod / -user terraform@pve -role TerraformProv

# Create API token (SAVE THIS VALUE!)
pveum user token add terraform@pve terraform-token --privsep=0
```

```bash
# Create Ubuntu template
cd /tmp
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
qm create 9001 --memory 2048 --cores 2 --name ubuntu2404-cloud --net0 virtio,bridge=vmbr0
qm importdisk 9001 noble-server-cloudimg-amd64.img local-lvm
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0
qm set 9001 --ide2 local-lvm:cloudinit --boot c --bootdisk scsi0 --serial0 socket --vga serial0
qm template 9001
rm noble-server-cloudimg-amd64.img
```

### 1.3 Validation

Test API authentication works:

```bash
curl -k -H 'Authorization: PVEAPIToken=terraform@pve!terraform-token=YOUR_TOKEN_VALUE' \
  https://YOUR_PROXMOX_IP:8006/api2/json/version
```

✅ **Success**: You should see: `{"data":{"version":"9.0.3"...}}`

> ⚠️ **Issues?** The [detailed Proxmox guide](proxmox-setup.md) has complete troubleshooting for authentication problems, privilege errors, and template creation issues.

## Step 2: Workstation Setup

This step installs the required tools on your local machine and creates SSH keys for VM access.

> 📖 **Detailed Guide**: For platform-specific instructions, corporate network setup, and troubleshooting, see **[Workstation Setup Guide](workstation-setup.md)**

### 2.1 Install Required Tools

**Windows (using Chocolatey - recommended):**
```powershell
# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required tools
choco install terraform git vscode openssh -y
```

**Linux/macOS:**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install terraform git openssh-client -y

# macOS (with Homebrew)
brew install terraform git openssh
```

### 2.2 Generate SSH Key

```bash
# Generate SSH key for secure VM access
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/proxmox_key

# Display public key (save this - you'll need it for Terraform!)
cat ~/.ssh/proxmox_key.pub
```

### 2.3 Verify Installation

```bash
terraform version  # Should show v1.5+
git --version     # Should show installed version  
ssh -V           # Should show OpenSSH version
```

> 💡 **Tip**: Save your SSH public key somewhere safe - you'll need to paste it into the Terraform configuration.

## Step 3: Terraform Configuration

This step creates the infrastructure-as-code configuration files and sets up your specific environment values.

> 📖 **Complete Reference**: See [Terraform Configuration Guide](terraform-configuration.md) for all configuration options, examples, and advanced setups.

### 3.1 Get the Repository

```bash
# If you cloned this repo already:
cd vuv-lab-infra

# If starting fresh:
git clone <your-repo-url>
cd vuv-lab-infra
```

### 3.2 Configure Your Environment

Create your environment-specific settings:

```bash
# Copy the example configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your specific values
# (Use any text editor like nano, vim, or VS Code)
nano terraform/terraform.tfvars
```

**Your `terraform.tfvars` should look like:**
```hcl
proxmox_host              = "192.168.1.91"      # Your Proxmox IP
proxmox_api_token_secret  = "your-token-here"   # From Step 1
proxmox_node              = "pve"               # Your node name
template_name             = "ubuntu2404-cloud"  # Template from Step 1
ssh_public_key            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-email@example.com"  # From Step 2
```

### 3.3 Initialize and Test

```bash
cd terraform

# Initialize Terraform (downloads providers)
terraform init

# Validate configuration syntax
terraform validate

# Preview what will be created
terraform plan
```

✅ **Success**: `terraform plan` should show it will create 1 VM without errors.

> ⚠️ **Problems?** The [Terraform configuration guide](terraform-configuration.md) covers all file structures, troubleshooting provider issues, and variable validation.

## Step 4: First Deployment

Now for the exciting part - let's deploy a test VM to verify your entire setup works end-to-end!

### 4.1 Deploy Test VM

```bash
# Deploy your first VM!
terraform apply

# Type 'yes' when prompted
```

**What happens:**
- Terraform connects to Proxmox using your API token
- Clones your Ubuntu template to create a new VM
- Configures cloud-init with your SSH key
- Starts the VM and waits for it to be ready

**Expected time:** 2-3 minutes

### 4.2 Test VM Access

```bash
# Get the VM's IP address
terraform output vm_ips

# SSH into your new VM (replace with actual IP)
ssh -i ~/.ssh/proxmox_key ubuntu@<VM_IP>

# Test basic functionality
uptime
sudo apt update
exit
```

✅ **Success**: You should be able to SSH in and run commands!

### 4.3 Cleanup Test Resources

Since this is just a test, clean up the resources:

```bash
# Remove the test VM
terraform destroy

# Type 'yes' when prompted
```

> 💡 **What we just proved**: Your infrastructure foundation works! Terraform can authenticate to Proxmox, clone templates, create VMs, and you can access them securely.

---

## 🎯 **What's Next: Configuration Management**

**Congratulations!** You now have working infrastructure, but the VMs are "blank slates" that need configuration. This is where **Ansible** comes in.

### Why Configuration Management?

Your VMs currently have:
- ✅ Basic Ubuntu installation
- ✅ SSH access with your key
- ❌ No application software
- ❌ No security hardening  
- ❌ No service configuration
- ❌ No team access management

**Ansible will configure your VMs** with proper users, security settings, and prepare them for service deployment.

### Ready for Phase 2?

**Continue to: [Step 5: Ansible Configuration Management](#step-5-ansible-configuration-management)** ⬇️

---

## Step 5: Ansible Configuration Management

Now that you have working VM deployments, it's time to set up configuration management with Ansible.

> 📖 **Complete Reference**: See [Ansible Setup Guide](ansible-setup.md) for detailed installation, team SSH key management, and troubleshooting.

### 5.1 Install Ansible

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install ansible -y
```

**Windows with WSL2:**
```bash
sudo apt install ansible python3-pip -y
```

**macOS:**
```bash
brew install ansible
```

**Windows with Chocolatey:**
```powershell
choco install ansible -y
```

### 5.2 Prepare for Configuration Management

```bash
# Navigate to the ansible directory
cd ansible

# Deploy some VMs for configuration (using your working Terraform)
cd ../terraform
terraform apply  # Deploy a few VMs for testing

# Get VM IP addresses
terraform output vm_ips
```

### 5.3 Bootstrap VMs for Ansible

Update the inventory with your actual VM IPs:

```bash
# Edit inventory with your VM IPs
nano inventory/hosts

# Example entry:
# gns3-server ansible_host=192.168.1.20
```

Run the bootstrap playbook to create the `lab` user:

```bash
# Bootstrap VMs (creates 'lab' user with passwordless sudo)
ansible-playbook -k playbooks/bootstrap.yml

# When prompted, enter password for your initial VM user (e.g., ubuntu)
```

### 5.4 Verify Ansible Management

```bash
# Test connectivity to all managed VMs
ansible all -m ping

# Should return SUCCESS for all hosts
```

✅ **Success**: Your VMs are now ready for configuration management!

### 5.5 Apply Basic Configuration

```bash
# Run system updates on all VMs
ansible-playbook playbooks/system_updates.yml

# Apply security hardening
ansible-playbook playbooks/security_hardening.yml
```

> 💡 **What we just accomplished**: VMs are now configured with proper user accounts, security settings, and ready for service deployment.

---

## 🎯 **Ready for Service Deployment!**

**Excellent work!** You now have a complete infrastructure and configuration management foundation.

### What You've Built

Your lab infrastructure now includes:
- ✅ **Secure Proxmox environment** with API access
- ✅ **Infrastructure as Code** with Terraform
- ✅ **Configuration Management** with Ansible  
- ✅ **Team collaboration** capabilities
- ✅ **Security hardening** applied to all VMs
- ✅ **Standardized VM management** via the `lab` user

### Next Steps: Service Deployment

You're now ready to deploy actual lab services:
- **GNS3 Server** for network simulation
- **DNS Infrastructure** for name resolution
- **Monitoring Stack** (Prometheus + Grafana)
- **Docker Hosts** for containerized services
- **Traefik Proxy** for reverse proxy and load balancing

> 📖 **Service Guides**: Check the `docs/` directory for service-specific deployment guides.

---

## Comprehensive Validation Checklist

Use this checklist to confirm everything is working before service deployment:

> 📖 **Complete Validation**: For comprehensive testing procedures, see [Validation & Testing Guide](validation-testing.md)

### Core Infrastructure
- [ ] Proxmox web interface accessible at https://your-ip:8006
- [ ] Terraform user (terraform@pve) can authenticate via API token
- [ ] Ubuntu template (ID 9001) exists and shows `template: 1` in config
- [ ] Your workstation has Terraform, Git, and SSH properly installed

### Deployment Testing
- [ ] `terraform init` completes without errors
- [ ] `terraform plan` shows planned VM creation
- [ ] `terraform apply` successfully creates a test VM
- [ ] SSH access to deployed VM works: `ssh -i ~/.ssh/proxmox_key ubuntu@<vm-ip>`
- [ ] `terraform destroy` cleanly removes test resources

### Configuration Management
- [ ] Ansible installed and version 2.15+ verified
- [ ] VM inventory updated with actual IP addresses
- [ ] Bootstrap playbook creates `lab` user successfully
- [ ] `ansible all -m ping` returns SUCCESS for all VMs
- [ ] System updates and security hardening applied

### Security & Access
- [ ] API token is saved securely (not in version control)
- [ ] SSH private key is protected (not in version control)
- [ ] VM gets proper IP address via DHCP
- [ ] Cloud-init completes successfully on VM

✅ **All checked?** Congratulations! Your VUV lab infrastructure is ready for advanced configurations.

## What You've Accomplished

🎉 **You now have a complete Infrastructure-as-Code setup that can:**

- **Provision VMs** on demand using Terraform
- **Configure systems** automatically using Ansible
- **Secure access** via SSH keys and API tokens  
- **Reproducible deployments** through version-controlled configuration
- **Team collaboration** with shared SSH keys and standardized processes
- **Clean resource management** with proper lifecycle controls

## Next Steps

With your foundation working, you can now:

1. **📚 Learn More**: Study the detailed guides to understand the components better
2. **🔧 Customize**: Modify VM specifications, create multiple VMs, or different templates
3. **🌐 Networking**: Set up advanced network configurations and VLANs
4. **📦 Services**: Deploy actual services like GNS3, Docker hosts, or monitoring
5. **👥 Team Setup**: Configure additional team members' SSH keys for collaborative access
6. **🔄 CI/CD**: Implement automated testing and deployment workflows

## Getting Help

### When Things Don't Work
- **Proxmox Issues**: Check [Proxmox Setup Guide](proxmox-setup.md) troubleshooting sections
- **Terraform Problems**: See [Terraform Configuration Guide](terraform-configuration.md) debugging section  
- **SSH/Networking**: Review [Validation Guide](validation-testing.md) connectivity troubleshooting
- **General Issues**: Create an issue in the project repository

### Learning Resources
- **Project Documentation**: Complete guides in the `docs/` directory
- **Proxmox Documentation**: https://pve.proxmox.com/wiki/
- **Terraform Proxmox Provider**: https://registry.terraform.io/providers/Telmate/proxmox/
- **University IT**: Contact your IT department for environment-specific questions

---

🎯 **Ready for Production**: Your infrastructure foundation is solid. Time to build something amazing!