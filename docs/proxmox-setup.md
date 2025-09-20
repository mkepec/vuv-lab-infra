# Proxmox VE Setup for Terraform

This document provides detailed instructions for preparing Proxmox VE to work with Terraform for infrastructure provisioning.

## Overview

Proxmox VE requires specific user permissions, API authentication, and VM templates to work effectively with Terraform. This guide ensures a secure and functional setup.

## Prerequisites

- Fresh Proxmox VE 9.x installation
- Root access to Proxmox host
- Basic understanding of Proxmox concepts

## Post-Installation Repository Configuration

After a fresh Proxmox VE installation, you need to configure repositories for systems without a subscription to avoid the "You do not have a valid subscription" warning and enable package updates.

### Disable Enterprise Repositories

The enterprise repositories require a paid subscription. Disable them for educational/testing use by renaming the files:

```bash
# Disable Proxmox VE enterprise repository
mv /etc/apt/sources.list.d/pve-enterprise.sources /etc/apt/sources.list.d/pve-enterprise.sources.disabled

# Disable Ceph enterprise repository
mv /etc/apt/sources.list.d/ceph.sources /etc/apt/sources.list.d/ceph.sources.disabled

# Verify enterprise repositories are disabled
ls -la /etc/apt/sources.list.d/*.disabled
```

### Enable No-Subscription Repositories

Add the required no-subscription repositories for updates:

```bash
# Create the Proxmox VE no-subscription repository
cat > /etc/apt/sources.list.d/proxmox.sources << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Create the Ceph no-subscription repository
cat > /etc/apt/sources.list.d/ceph.sources << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Update Debian repositories for proper package sources
cat > /etc/apt/sources.list.d/debian.sources << 'EOF'
Types: deb deb-src
URIs: http://deb.debian.org/debian/
Suites: trixie trixie-updates
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# Update package lists
apt update

# Verify repositories are working
apt list --upgradable
```

### Remove Subscription Warning (Web UI)

The repository configuration enables updates but doesn't remove the subscription warning popup in the web interface. To disable this warning for educational use:

```bash
# Backup the original file
cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.backup

# Disable the subscription warning popup
sed -i "s/Ext\.Msg\.show/void/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# Verify the change was made
grep -n "void(" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# Restart Proxmox web service to apply changes
systemctl restart pveproxy
```

**Note**: This change removes the subscription warning popup from the web interface. The modification is safe for educational environments but will need to be reapplied after Proxmox updates.

### Update System Packages

After configuring repositories, update the system:

```bash
# Update package database
apt update

# Upgrade all packages
apt full-upgrade -y

# Reboot if kernel was updated
reboot
```

**Note**: The no-subscription repository is suitable for testing and educational environments like the VUV lab. For production environments, consider purchasing a Proxmox VE subscription for enterprise support and more stable packages.

## User and Authentication Setup

### Create Terraform Role

Proxmox uses role-based access control. Create a role with all required privileges for Terraform operations including guest agent support:

```bash
# Store privileges in variable for easier management and updates
# This approach allows easy role modification and ensures consistency
PRIVS="VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Migrate,VM.PowerMgmt,VM.Snapshot,Datastore.AllocateSpace,Datastore.Audit,Pool.Allocate,Pool.Audit,SDN.Use,Sys.Audit,Sys.Console,Sys.Modify,VM.GuestAgent.Audit,VM.GuestAgent.Unrestricted"

# Create role with comprehensive privileges for Terraform operations
pveum role add TerraformProv -privs "$PRIVS"

# Verify role creation
pveum role list | grep TerraformProv
pveum role list
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

# Enable QEMU guest agent with enhanced configuration for Terraform compatibility
qm set 9001 --agent enabled=1,fstrim_cloned_disks=1,freeze-fs-on-backup=1,type=virtio

# Enable serial console (useful for debugging)
qm set 9001 --serial0 socket --vga serial0
```

### Convert to Template

```bash
# Convert VM to template (this renames disk to base-*)
qm template 9001

# Verify template creation and configuration
qm list | grep 9001
qm config 9001

# Validate template configuration for Terraform compatibility
echo "=== Template Validation ==="
echo -n "Template status: " && qm config 9001 | grep "template:" | cut -d: -f2
echo -n "Guest agent: " && qm config 9001 | grep "agent:" | cut -d: -f2
echo -n "Cloud-init drive: " && qm config 9001 | grep "ide2:" | cut -d: -f2
echo -n "Network config: " && qm config 9001 | grep "net0:" | cut -d: -f2 | cut -d, -f1
echo -n "Boot disk: " && qm config 9001 | grep "boot:" | cut -d: -f2

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
# Download Ubuntu 24.04 LTS template (primary Linux distribution)
pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst

# Download Rocky Linux 9 template (RHEL-compatible for enterprise education)
pveam download local rockylinux-9-default_20240912_amd64.tar.xz
```

### Check Available Templates

If you need to verify what templates are available:

```bash
# Check available Ubuntu and Rocky Linux templates
pveam available | grep "ubuntu-24.04"
pveam available | grep "rockylinux-9"
```

### Verify Template Downloads

```bash
# List all downloaded templates
pveam list local

# Check downloaded templates
pveam list local | grep -E "(ubuntu|rocky)"

# Verify template files exist
ls -la /var/lib/vz/template/cache/ | grep -E "(ubuntu-24.04|rockylinux-9)"

# Check template details
pveam list local | grep -E "ubuntu-24.04|rockylinux-9"
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

### Optional Templates

Consider downloading these templates for specific use cases:

```bash
# Alpine Linux (minimal footprint - ideal for microservices, testing, resource-constrained environments)
pveam download local alpine-3.22-default_20250617_amd64.tar.xz

# Debian 12 (stable base for projects requiring Debian-specific packages)
pveam download local debian-12-standard_12.12-1_amd64.tar.zst
```

**Note**: Alpine Linux is particularly useful when you need:
- **Small container footprint** (typically 5-10MB vs 100+MB for Ubuntu)
- **Fast startup times** for testing and development
- **Resource efficiency** in memory-constrained lab environments
- **Microservices development** where minimal base images are preferred

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


### Integration with Terraform

Update your Terraform configuration based on downloaded templates:

```bash
# Check exact template name
pveam list local

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

**Post-Installation Setup:**
- [ ] Enterprise repositories disabled (`.sources` files renamed to `.disabled`)
- [ ] Proxmox VE no-subscription repository enabled
- [ ] Ceph no-subscription repository enabled
- [ ] Debian repositories updated with proper sources
- [ ] Subscription warning popup disabled in web UI
- [ ] System packages updated (`apt full-upgrade`)
- [ ] Web interface accessible without subscription warnings

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
- [ ] Rocky Linux 9 LXC template downloaded
- [ ] LXC templates verified with `pveam list local | grep -E "(ubuntu|rocky)"`
- [ ] Template files exist in `/var/lib/vz/template/cache/`

**Integration Testing:**
- [ ] Manual VM clone test completed successfully (`qm clone 9001 999`)
- [ ] Guest agent responds to ping and commands
- [ ] Test VM cleanup completed (`qm destroy 999`)

**Storage & Infrastructure:**
- [ ] Storage pools are active and accessible (`pvesm status`)
- [ ] Sufficient storage space available (`df -h /var/lib/vz/`)
- [ ] Network bridge `vmbr0` configured and active

## Advanced Proxmox Commands

### VM Management and Monitoring
```bash
# Interactive API shell for troubleshooting
pvesh ls /nodes

# Check VM resource usage and status
pvesh get /nodes/localhost/qemu/<vmid>/status/current

# Monitor VM logs
journalctl -u qemu-server@<vmid> -f

# Test guest agent functionality (after VM is running and guest agent is installed)
qm guest cmd <vmid> get-time
qm guest cmd <vmid> get-osinfo
qm guest exec <vmid> -- ls -la /
```

### Storage Management
```bash
# Check storage status and usage
pvesm status
pvesm list local-lvm
df -h /var/lib/vz/

# Backup operations
vzdump --dump --dumpdir /var/lib/vz/dump <vmid>
```

### Network and System Information
```bash
# Check network bridges
ip link show
brctl show

# System resource monitoring
pvesh get /nodes/localhost/status
cat /proc/version
pveversion
```

## Terraform Integration Testing

Before using Terraform, test VM cloning manually:

```bash
# Test VM cloning (simulates Terraform behavior)
qm clone 9001 999 --name test-terraform-clone

# Configure basic cloud-init for the test VM (required for cloud images to boot properly)
qm set 999 --ciuser ubuntu
qm set 999 --cipassword $(openssl passwd -6 "testpass123")
qm set 999 --ipconfig0 ip=dhcp

# Start cloned VM
qm start 999

# Check VM status
qm status 999

# Cleanup test VM when done
qm stop 999 && qm destroy 999
```

### Manual Testing Steps

After running the commands above:

1. **Monitor VM boot**: `qm terminal 999`
2. **Login**: ubuntu/testpass123
3. **Check IP**: `ip addr show`
4. **Install guest agent**: `sudo apt update && sudo apt install qemu-guest-agent -y`
5. **Enable service**: `sudo systemctl enable --now qemu-guest-agent`
6. **Alternative**: SSH to VM IP if network permits

**Note about Guest Agent**: The Ubuntu cloud image template doesn't include the QEMU guest agent by default. This is normal and expected. When using Terraform with cloud-init, you can install the guest agent during VM provisioning:

```yaml
# Example cloud-init configuration to install guest agent
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
```

The guest agent will be available once it's installed and the VM is rebooted. For the manual test, a successful VM start/stop cycle confirms the template works correctly for Terraform.

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

### Permission Errors: Missing Privileges

If you get permission errors like `Sys.Modify`, `VM.GuestAgent.Audit`, or `VM.GuestAgent.Unrestricted` missing:

**Option 1: Update existing role (recommended)**
```bash
# Store comprehensive privileges in variable for easier management
PRIVS="VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Migrate,VM.PowerMgmt,VM.Snapshot,Datastore.AllocateSpace,Datastore.Audit,Pool.Allocate,Pool.Audit,SDN.Use,Sys.Audit,Sys.Console,Sys.Modify,VM.GuestAgent.Audit,VM.GuestAgent.Unrestricted"

# Update role with all required permissions
pveum role modify TerraformProv -privs "$PRIVS"

# Verify the permissions were updated
pveum role list | grep TerraformProv
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

# If guest agent not working after template creation:
qm set 9001 --agent enabled=1,fstrim_cloned_disks=1,freeze-fs-on-backup=1,type=virtio

# Reset cloud-init if needed
qm set 9001 --delete ide2
qm set 9001 --ide2 local-lvm:cloudinit
```

### Common Terraform Integration Issues
```bash
# Guest agent timeout errors
# Verify guest agent is properly configured:
qm config <vmid> | grep agent

# Test guest agent after VM starts:
qm guest ping <vmid>

# Cloud-init not working
# Check cloud-init configuration:
qm config <vmid> | grep ide2
# Reset if necessary:
qm set <vmid> --delete ide2 && qm set <vmid> --ide2 local-lvm:cloudinit

# VM clone fails
# Check storage permissions and space:
pvesm status
df -h /var/lib/vz/

# Network issues with cloned VMs
# Verify bridge configuration:
ip link show vmbr0
brctl show vmbr0
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

### Proxmox VE Documentation
- [Proxmox VE Documentation Index](https://pve.proxmox.com/pve-docs/) - Complete official documentation
- [Proxmox VE User Management](https://pve.proxmox.com/wiki/User_Management)
- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Cloud-Init in Proxmox](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [qm Command Reference](https://pve.proxmox.com/pve-docs/qm.1.html) - VM management commands
- [pct Command Reference](https://pve.proxmox.com/pve-docs/pct.1.html) - Container management commands
- [pveum Command Reference](https://pve.proxmox.com/pve-docs/pveum.1.html) - User management commands
- [pvesm Command Reference](https://pve.proxmox.com/pve-docs/pvesm.1.html) - Storage management commands

### Terraform Integration
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

### Additional Administration Resources
- [Proxmox VE Administration Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html) - Comprehensive administration manual
- [Proxmox VE Installation Guide](https://pve.proxmox.com/pve-docs/pve-installation.html) - Installation procedures