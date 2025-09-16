# Validation and Testing Guide

This document provides comprehensive validation procedures to ensure your VUV lab infrastructure setup is working correctly before proceeding with advanced configurations.

## Pre-Deployment Validation

Run these checks before attempting to deploy any infrastructure.

### 1. Proxmox VE Health Check

#### System Status

```bash
# Check Proxmox version and status
pveversion

# Verify cluster status (even for single node)
pvecm status

# Check storage health
pvesm status

# Review system resources
free -h
df -h
```

#### Network Connectivity

```bash
# Test network bridge configuration
ip addr show vmbr0

# Verify bridge is up and has correct IP
brctl show vmbr0

# Test internet connectivity from Proxmox
ping -c 3 google.com
```

### 2. Authentication Validation

#### API Token Test

**Linux/macOS/WSL:**
```bash
# Set variables for testing
PROXMOX_HOST="your-proxmox-ip"
API_TOKEN="your-token-value"

# Test API endpoint
curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform-token=${API_TOKEN}" \
  https://${PROXMOX_HOST}:8006/api2/json/version

# Expected: {"data":{"version":"9.0.3","release":"9.0"...}}
```

**Windows CMD:**
```cmd
set PROXMOX_HOST=your-proxmox-ip
set API_TOKEN=your-token-value

curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform-token=%API_TOKEN%" https://%PROXMOX_HOST%:8006/api2/json/version
```

#### User Permissions Check

```bash
# Verify terraform user permissions
pveum user permissions terraform@pve

# Check role assignments
pveum acl list | grep terraform

# Verify role privileges
pveum role show TerraformProv
```

### 3. Template Validation

#### Template Existence

```bash
# List all templates
qm list | grep template

# Check specific template
qm list 9001
qm config 9001 | grep template

# Verify template disk exists
ls -la /var/lib/vz/images/9001/
```

#### Template Testing

```bash
# Test clone operation (creates test VM)
qm clone 9001 999 --name test-clone-validation

# Check if clone succeeded
qm list 999

# Start test VM
qm start 999

# Wait a moment then check status
sleep 30
qm status 999

# Clean up test VM
qm stop 999
qm destroy 999
```

### 4. Workstation Setup Validation

#### Tool Versions

```bash
# Check required tools
terraform version
git --version
ssh -V

# Verify SSH key exists
ls -la ~/.ssh/proxmox_key*
```

#### SSH Key Validation

```bash
# Check key format
ssh-keygen -l -f ~/.ssh/proxmox_key.pub

# Test key format (should not error)
ssh-keygen -y -f ~/.ssh/proxmox_key > /dev/null
```

## Terraform Configuration Validation

### 1. Configuration Syntax

```bash
cd terraform

# Check configuration syntax
terraform validate

# Format check
terraform fmt -check

# Show planned changes without applying
terraform plan
```

### 2. Variable Validation

Create a test configuration to validate variables:

```bash
# Check required variables are set
terraform plan -var-file=terraform.tfvars
```

### 3. Provider Connectivity

```bash
# Initialize with debug logging
export TF_LOG=INFO
terraform init

# Test provider connectivity
terraform plan
```

## Deployment Testing

### 1. Single VM Test

Deploy one VM to test the complete workflow:

```bash
# Create minimal test configuration
cat > test-single-vm.tf << 'EOF'
resource "proxmox_vm_qemu" "test_vm" {
  name        = "test-validation-vm"
  target_node = var.proxmox_node
  
  clone      = var.template_name
  full_clone = true
  
  cores  = 1
  memory = 1024
  
  disk {
    slot    = 0
    size    = "10G"
    type    = "scsi" 
    storage = "local-lvm"
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  os_type   = "cloud-init"
  ipconfig0 = "ip=dhcp"
  ciuser    = var.vm_user
  sshkeys   = var.ssh_public_key
}
EOF

# Deploy test VM
terraform apply -target=proxmox_vm_qemu.test_vm
```

### 2. VM Accessibility Test

```bash
# Get VM IP (may take a few minutes for cloud-init)
terraform show | grep default_ipv4_address

# Test SSH access
VM_IP=$(terraform show | grep default_ipv4_address | head -1 | cut -d'"' -f4)
ssh -i ~/.ssh/proxmox_key -o ConnectTimeout=10 ubuntu@${VM_IP} uptime
```

### 3. VM Functionality Test

```bash
# Test VM basic functionality
ssh -i ~/.ssh/proxmox_key ubuntu@${VM_IP} << 'EOSSH'
# Test cloud-init completed
sudo cloud-init status

# Test package management
sudo apt update

# Test network connectivity
ping -c 3 google.com

# Test disk space
df -h

# Test system info
hostnamectl
EOSSH
```

### 4. Cleanup Test

```bash
# Test resource destruction
terraform destroy -target=proxmox_vm_qemu.test_vm

# Verify VM is removed
qm list | grep test-validation
```

## Validation Checklist

Use this checklist to ensure complete validation:

### Proxmox VE Readiness
- [ ] Proxmox web interface accessible at https://proxmox-ip:8006
- [ ] System resources adequate (CPU, RAM, storage)
- [ ] Network bridge (vmbr0) configured and operational
- [ ] Storage pools (local-lvm) active and accessible
- [ ] System version is 9.x and up to date

### Authentication Setup
- [ ] TerraformProv role created with correct privileges
- [ ] terraform@pve user created and role assigned
- [ ] API token generated and saved securely
- [ ] API authentication test passes
- [ ] User permissions validated via pveum commands

### Template Configuration
- [ ] Ubuntu 24.04 template (ID 9001) exists
- [ ] Template has correct cloud-init configuration
- [ ] Template clone test succeeds
- [ ] Template disk is in base-* format
- [ ] Template networking configured properly

### Workstation Setup
- [ ] Terraform installed and accessible
- [ ] Git configured for version control
- [ ] SSH client available and configured
- [ ] SSH key pair generated (ed25519 format)
- [ ] SSH public key correctly formatted

### Terraform Configuration
- [ ] All configuration files syntax valid
- [ ] terraform.tfvars contains correct values
- [ ] Provider authentication successful
- [ ] Variable validation passes
- [ ] Terraform plan executes without errors

### Deployment Testing
- [ ] Single test VM deploys successfully
- [ ] VM receives IP address via DHCP
- [ ] SSH access to deployed VM works
- [ ] Cloud-init completes successfully
- [ ] VM has internet connectivity
- [ ] Resource cleanup/destruction works

## Troubleshooting Common Validation Failures

### Proxmox API Not Accessible

**Symptoms:** Connection refused, timeout errors

**Solutions:**
1. Check Proxmox service status: `systemctl status pveproxy`
2. Verify firewall settings: `iptables -L | grep 8006`
3. Check network connectivity: `ping proxmox-host`
4. Validate SSL certificate issues

### Authentication Failures

**Symptoms:** 401 Unauthorized, token errors

**Solutions:**
1. Verify token format: no extra spaces or characters
2. Check user permissions: `pveum user permissions terraform@pve`
3. Validate role privileges: `pveum role show TerraformProv`
4. Test with curl directly before Terraform

### Template Issues

**Symptoms:** Template not found, clone failures

**Solutions:**
1. Verify template exists: `qm list 9001`
2. Check template flag: `qm config 9001 | grep template`
3. Validate template disk: `ls /var/lib/vz/images/9001/`
4. Re-create template if necessary

### Network Connectivity Issues

**Symptoms:** VM has no IP, SSH connection refused

**Solutions:**
1. Check cloud-init status in VM console
2. Verify network bridge configuration
3. Check DHCP server availability
4. Validate SSH key format and content

### Resource Constraints

**Symptoms:** VM creation fails, insufficient resources

**Solutions:**
1. Check available storage: `df -h /var/lib/vz`
2. Verify memory availability: `free -h`
3. Check CPU allocation limits
4. Review storage pool configuration

## Automated Validation Script

Create a validation script for routine checks:

```bash
#!/bin/bash
# validation-check.sh

set -e

echo "=== VUV Lab Infrastructure Validation ==="

# Check Proxmox connectivity
echo "Testing Proxmox API..."
curl -k -s -H "Authorization: PVEAPIToken=terraform@pve!terraform-token=${PROXMOX_API_TOKEN}" \
  https://${PROXMOX_HOST}:8006/api2/json/version > /dev/null
echo "✓ Proxmox API accessible"

# Check template
echo "Validating template..."
if qm list 9001 | grep -q "template"; then
  echo "✓ Template 9001 exists"
else
  echo "✗ Template 9001 not found"
  exit 1
fi

# Check Terraform
echo "Validating Terraform configuration..."
cd terraform
terraform validate > /dev/null
echo "✓ Terraform configuration valid"

echo "=== All validation checks passed ==="
```

## Performance Benchmarking

After successful validation, run performance tests:

### VM Deployment Time
```bash
# Time VM creation
time terraform apply

# Typical times:
# - VM creation: 30-60 seconds
# - Cloud-init completion: 60-120 seconds
# - Total deployment: 2-3 minutes
```

### Resource Utilization
```bash
# Check Proxmox resource usage during deployment
htop  # Monitor CPU and memory
iotop # Monitor disk I/O
```

## Next Steps After Validation

Once all validation passes:

1. **Document Configuration** - Save working terraform.tfvars template
2. **Create Backups** - Backup Proxmox configuration and templates
3. **Scale Testing** - Test with multiple VMs
4. **Advanced Features** - LXC containers, custom networks
5. **Automation Integration** - CI/CD, monitoring, Ansible

## Validation Reporting

Document validation results for future reference:

```bash
# Generate validation report
cat > validation-report.md << EOF
# Validation Report - $(date)

## Environment
- Proxmox Version: $(pveversion | head -1)
- Terraform Version: $(terraform version | head -1)
- Template: ubuntu2404-cloud (ID: 9001)

## Test Results
- API Authentication: PASS
- Template Validation: PASS
- VM Deployment: PASS
- SSH Connectivity: PASS
- Resource Cleanup: PASS

## Performance Metrics
- VM Creation Time: X seconds
- Cloud-init Time: Y seconds
- Total Deployment: Z minutes

Validated by: [Your Name]
Date: $(date)
EOF
```

This comprehensive validation ensures your infrastructure is ready for production workloads and advanced configurations.

---

## Next Steps

✅ **Infrastructure validation is complete!**

### Continue with Advanced Configurations

With your validated infrastructure foundation, you can now:

1. **Deploy Production Services** - GNS3, Docker hosts, monitoring systems
2. **Implement Ansible** - Automated configuration management
3. **Advanced Networking** - VLANs, firewall rules, network segmentation
4. **Monitoring & Logging** - Infrastructure observability
5. **Backup & Recovery** - Data protection procedures

### Guide Navigation

- ⬅️ **Previous**: [Terraform Configuration Guide](terraform-configuration.md) (infrastructure setup)
- 📋 **Overview**: Return to [Getting Started Guide](getting-started.md) (main process)
- 🏠 **Home**: Back to [Project README](../README.md) (project overview)

### What You've Accomplished

- ✅ Complete infrastructure deployment and testing
- ✅ Validated end-to-end workflow from Proxmox to deployed VMs
- ✅ Proven security, networking, and access controls
- ✅ Ready for production workloads and advanced configurations

🎉 **Congratulations!** Your VUV lab infrastructure is fully operational and ready for advanced use cases.