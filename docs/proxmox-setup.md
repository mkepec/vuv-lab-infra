# Proxmox VE Setup for Terraform

This document provides detailed instructions for preparing Proxmox VE to work with Terraform for infrastructure provisioning.

## Overview

Proxmox VE requires specific user permissions, API authentication, and VM templates to work effectively with Terraform. This guide ensures a secure and functional setup.

## Prerequisites

- Fresh Proxmox VE 9.x installation
- Root access to Proxmox host
- Basic understanding of Proxmox concepts

## User and Authentication Setup

### Create Terraform Role

Proxmox uses role-based access control. Create a role with minimal required privileges:

```bash
# Create role with specific privileges for Terraform operations
pveum role add TerraformProv -privs "VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Migrate,VM.PowerMgmt,VM.Snapshot,Datastore.AllocateSpace,Datastore.Audit,Pool.Allocate,Pool.Audit,SDN.Use,Sys.Audit,Sys.Console,Sys.Modify"

# Verify role creation
pveum role list | grep TerraformProv
```

### Create Terraform User

```bash
# Create dedicated user for Terraform
pveum user add terraform@pve --password "SecurePassword123!"

# Assign role to user with full propagation
pveum aclmod / -user terraform@pve -role TerraformProv

# Verify user permissions
pveum user permissions terraform@pve
```

### Generate API Token

API tokens are more secure than password authentication:

```bash
# Create API token (disable privilege separation for full user access)
pveum user token add terraform@pve terraform-token --privsep=0
```

**Important**: Save the token value immediately. It looks like:
```
┌──────────────┬──────────────────────────────────────┐
│ key          │ value                                │
╞══════════════╪══════════════════════════════════════╡
│ full-tokenid │ terraform@pve!terraform-token        │
├──────────────┼──────────────────────────────────────┤
│ value        │ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │
└──────────────┴──────────────────────────────────────┘
```

Save both the `full-tokenid` and `value` for Terraform configuration.

## VM Template Creation

Templates enable efficient VM cloning. We'll create an Ubuntu 24.04 LTS template:

### Download Cloud Image

```bash
# Change to temporary directory
cd /tmp

# Download Ubuntu 24.04 LTS Noble cloud image
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

### Create Base VM

```bash
# Create VM with appropriate resources
qm create 9001 \
  --memory 2048 \
  --cores 2 \
  --name ubuntu2404-cloud \
  --net0 virtio,bridge=vmbr0

# Import the cloud image as a disk
qm importdisk 9001 noble-server-cloudimg-amd64.img local-lvm
```

### Configure VM Hardware

```bash
# Set up SCSI controller and disk
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0

# Add cloud-init drive
qm set 9001 --ide2 local-lvm:cloudinit

# Configure boot settings
qm set 9001 --boot c --bootdisk scsi0

# Enable serial console (useful for debugging)
qm set 9001 --serial0 socket --vga serial0
```

### Convert to Template

```bash
# Convert VM to template (this renames disk to base-*)
qm template 9001

# Verify template creation
qm list 
qm list | grep 9001
qm config 9001

# Clean up downloaded image
rm noble-server-cloudimg-amd64.img
```

## LXC Container Template Setup

LXC containers require pre-built templates for quick deployment. These templates provide base operating systems for lightweight containerization.

### Update Available Templates

```bash
# Update the list of available container templates
pveam update

# View all available templates
pveam available

# Filter for Ubuntu templates specifically
pveam available | grep ubuntu
```

### Download Required Templates

For the VUV lab infrastructure, download these essential templates:

```bash
# Download Ubuntu 24.04 LTS template (latest stable)
pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst

# Alternative: Download Ubuntu 22.04 LTS for compatibility
pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst

# Download Ubuntu 20.04 LTS for legacy support (optional)
pveam download local ubuntu-20.04-standard_20.04-1_amd64.tar.zst
```

### Alternative Template Downloads

If specific versions aren't available, use these commands to find and download alternatives:

```bash
# Find latest Ubuntu 24.04 template
pveam available | grep "ubuntu-24.04" | head -1

# Download the first available Ubuntu 24.04 template
TEMPLATE=$(pveam available | grep "ubuntu-24.04" | head -1 | awk '{print $2}')
pveam download local $TEMPLATE

# For automation scripts - download latest available Ubuntu template
LATEST_UBUNTU=$(pveam available | grep "ubuntu-24.04-standard" | head -1 | awk '{print $2}')
if [ ! -z "$LATEST_UBUNTU" ]; then
  pveam download local $LATEST_UBUNTU
  echo "Downloaded: $LATEST_UBUNTU"
else
  echo "No Ubuntu 24.04 templates available"
fi
```

### Verify Template Downloads

```bash
# List all downloaded templates
pveam list local

# Check specific Ubuntu templates
pveam list local | grep ubuntu

# Verify template file exists
ls -la /var/lib/vz/template/cache/

# Check template details
pveam list local | grep ubuntu-24.04
```

### Template Storage Locations

Templates are stored in different locations based on configuration:

```bash
# Default location for templates
ls -la /var/lib/vz/template/cache/

# Check template storage configuration
pvesm status | grep vztmpl

# Verify storage usage
df -h /var/lib/vz/
```

### Additional Useful Templates

For extended lab functionality, consider downloading:

```bash
# Alpine Linux (minimal, fast startup)
pveam download local alpine-3.18-default_20230607_amd64.tar.xz

# Debian 12 (stable base)
pveam download local debian-12-standard_12.2-1_amd64.tar.zst

# CentOS Stream 9 (enterprise testing)
pveam download local centos-9-stream-default_20221109_amd64.tar.xz
```

### Template Cleanup (Optional)

To manage storage space, remove unused templates:

```bash
# List templates with sizes
pveam list local

# Remove specific template
pveam remove local:vztmpl/template-name.tar.zst

# Example: Remove old Ubuntu version
pveam remove local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.zst
```

### Automation Script for Template Management

Create a script for consistent template setup:

```bash
#!/bin/bash
# Template download script for VUV Lab Infrastructure

echo "Updating available templates..."
pveam update

echo "Downloading essential templates..."

# Ubuntu 24.04 LTS (primary)
if pveam available | grep -q "ubuntu-24.04-standard"; then
    UBUNTU_24=$(pveam available | grep "ubuntu-24.04-standard" | head -1 | awk '{print $2}')
    echo "Downloading Ubuntu 24.04: $UBUNTU_24"
    pveam download local $UBUNTU_24
else
    echo "Ubuntu 24.04 not available"
fi

# Ubuntu 22.04 LTS (fallback)
if pveam available | grep -q "ubuntu-22.04-standard"; then
    UBUNTU_22=$(pveam available | grep "ubuntu-22.04-standard" | head -1 | awk '{print $2}')
    echo "Downloading Ubuntu 22.04: $UBUNTU_22"
    pveam download local $UBUNTU_22
else
    echo "Ubuntu 22.04 not available"
fi

echo "Template download complete!"
echo "Available templates:"
pveam list local | grep ubuntu
```

Save this as `/root/setup-lxc-templates.sh` and run:

```bash
chmod +x /root/setup-lxc-templates.sh
/root/setup-lxc-templates.sh
```

### Integration with Terraform

Update your Terraform configuration based on downloaded templates:

```bash
# Check exact template name
pveam list local | grep ubuntu-24.04

# Use exact name in terraform.tfvars
# lxc_template = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
```

### Troubleshooting Template Issues

**Template Download Fails**:
```bash
# Check internet connectivity
ping -c 3 download.proxmox.com

# Check available space
df -h /var/lib/vz/

# Manually retry download
pveam download local template-name
```

**Template Not Found in Terraform**:
```bash
# Verify exact template name
pveam list local | grep ubuntu

# Check template location
ls -la /var/lib/vz/template/cache/ | grep ubuntu

# Verify storage configuration
cat /etc/pve/storage.cfg | grep "content.*vztmpl"
```

### Template Update Maintenance

For ongoing maintenance, create a monthly template update routine:

```bash
# Update template repository
pveam update

# Check for template updates
pveam available | grep ubuntu-24.04 | head -1

# Download newer versions as they become available
# Remove old versions after testing
```

## Authentication Testing

Verify the API token works correctly:

### Linux/macOS/WSL

```bash
# Test API authentication
curl -k -H 'Authorization: PVEAPIToken=terraform@pve!terraform-token=YOUR_TOKEN_VALUE' \
  https://YOUR_PROXMOX_IP:8006/api2/json/version
```

### Windows Command Prompt

```cmd
curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform-token=YOUR_TOKEN_VALUE" https://YOUR_PROXMOX_IP:8006/api2/json/version
```

### Windows PowerShell

```powershell
# Use curl.exe to avoid PowerShell cmdlet conflicts
curl.exe -k -H 'Authorization: PVEAPIToken=terraform@pve!terraform-token=YOUR_TOKEN_VALUE' https://YOUR_PROXMOX_IP:8006/api2/json/version
```

### Expected Response

A successful authentication returns:
```json
{"data":{"version":"9.0.3","release":"9.0","repoid":"xxxxxxxxx"}}
```

## Storage Configuration

Verify default storage is available:

```bash
# Check storage status
pvesm status

# Should show both local and local-lvm as active
```

Default configuration should include:
- `local` - For ISO images, container templates, backups
- `local-lvm` - For VM disks and containers

## Security Considerations

### API Token Security
- Store tokens securely (environment variables, secret management)
- Use privilege separation (`--privsep=1`) when possible for production
- Rotate tokens regularly
- Limit token scope to specific resources when available

### Network Security
- Use TLS certificates in production (not self-signed)
- Consider firewall rules for API access
- Implement network segmentation for management interfaces

### User Permissions
- Follow principle of least privilege
- Review and audit role permissions regularly
- Use separate users for different automation tools

## Validation Checklist

Before proceeding with Terraform:

**Authentication & Permissions:**
- [ ] TerraformProv role created with required privileges
- [ ] terraform@pve user created and role assigned
- [ ] API token generated and saved securely
- [ ] Authentication test passes (returns version info)

**VM Templates:**
- [ ] Ubuntu 24.04 VM template created (ID 9001)
- [ ] Template verification shows `template: 1` in config
- [ ] VM template accessible via `qm list | grep 9001`

**LXC Templates:**
- [ ] LXC template repository updated (`pveam update`)
- [ ] Ubuntu 24.04 LXC template downloaded
- [ ] LXC templates verified with `pveam list local | grep ubuntu`
- [ ] Template file exists in `/var/lib/vz/template/cache/`

**Storage & Infrastructure:**
- [ ] Storage pools are active and accessible (`pvesm status`)
- [ ] Sufficient storage space available (`df -h /var/lib/vz/`)
- [ ] Network bridge `vmbr0` configured and active

## Troubleshooting

### Role Creation Fails
```bash
# Error: invalid privilege 'SomePrivilege'
# Solution: Check available privileges for your Proxmox version
pveum role list --output-format json

# Use only privileges that exist in your installation
```

### User Already Exists
```bash
# If terraform user exists from previous setup:
# Check current permissions
pveum user permissions terraform@pve

# Update role assignment if needed
pveum aclmod / -user terraform@pve -role TerraformProv
```

### Permission Error: "Sys.Modify" Missing
If you get `permissions for user/token terraform@pve are not sufficient, please provide also the following permissions that are missing: [Sys.Modify]`:

**Option 1: Update existing role (recommended)**
```bash
# Store privileges in variable for easier management
PRIVS="VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Migrate,VM.PowerMgmt,VM.Snapshot,Datastore.AllocateSpace,Datastore.Audit,Pool.Allocate,Pool.Audit,SDN.Use,Sys.Audit,Sys.Console,Sys.Modify,VM.GuestAgent.Audit"

# Update role with all required permissions including guest agent
pveum role modify TerraformProv -privs "$PRIVS"

# Verify the permissions were added
pveum role show TerraformProv
```

**Option 2: Quick fix - assign Administrator role (less secure)**
```bash
# Temporarily assign Administrator role for testing
pveum aclmod / -user terraform@pve -role Administrator

# Remove old role assignment
pveum aclmod / -user terraform@pve -role TerraformProv -delete
```

### API Token Test Fails
- Verify token value copied correctly (no extra whitespace)
- Check user has required permissions
- Ensure Proxmox API is accessible on port 8006
- Try different authentication method (curl vs PowerShell)

### Template Creation Issues
```bash
# If disk import fails:
# Check available storage space
df -h /var/lib/vz

# Verify storage configuration
pvesm status

# Check template conversion worked
qm config 9001 | grep template
# Should show: template: 1
```

## Next Steps

✅ **Proxmox VE is now ready for Terraform!**

### Continue with the Setup Process

1. **Return to Getting Started**: Go back to [Getting Started Guide](getting-started.md#step-2-workstation-setup) to continue with Step 2: Workstation Setup
2. **Next Detailed Guide**: Proceed to [Workstation Setup Guide](workstation-setup.md) for platform-specific tool installation and configuration

### What You've Accomplished

- ✅ Secure terraform user with appropriate permissions
- ✅ API token authentication configured
- ✅ Ubuntu 24.04 LTS template ready for cloning
- ✅ All authentication tests passing

### Guide Navigation

- ⬅️ **Previous**: [Getting Started Guide](getting-started.md) (overview)
- ➡️ **Next**: [Workstation Setup Guide](workstation-setup.md) (detailed workstation configuration)
- 📋 **Alternative**: Continue with [Getting Started Step 2](getting-started.md#step-2-workstation-setup) (basic steps)

---

## References

- [Proxmox VE User Management](https://pve.proxmox.com/wiki/User_Management)
- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Cloud-Init in Proxmox](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)