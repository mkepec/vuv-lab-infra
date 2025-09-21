# Services Deployment Guide

This guide provides step-by-step instructions for deploying specific services on VUV Lab Infrastructure after completing the **[Ansible foundation setup](ansible-setup.md)**.

## Prerequisites

Before deploying any service, ensure you have completed:

- ✅ **[Proxmox Setup](proxmox-setup.md)** - Hypervisor with templates ready
- ✅ **[Terraform Configuration](terraform-configuration.md)** - Infrastructure provisioning working  
- ✅ **[Ansible Setup](ansible-setup.md)** - Foundation playbooks tested and working

## Service Deployment Overview

Each service deployment follows this reliable pattern:

### 1. Foundation Setup
Apply basic configuration to new VMs:
```bash
# Navigate to ansible directory
cd ansible

# Apply foundation setup to service group
ansible-playbook --limit [service-group] site.yml
```

### 2. Service Deployment
Deploy the specific service:
```bash
# Deploy specific service
ansible-playbook playbooks/[service].yml
```

### 3. Verification
Test the deployment using provided commands and web interface access.

---

## GNS3 Server Deployment

Deploy network simulation platform for laboratory exercises.

### Prerequisites
- ✅ **Foundation setup completed** (from Ansible setup guide)
- ✅ **VM provisioned** via Terraform with sufficient resources (4+ CPU cores, 8GB+ RAM)  
- ✅ **Network connectivity** verified to gns3-1

### Find Your GNS3 Server IP Address

Before starting, locate your GNS3 server IP address:

**Option 1 - Ansible Inventory:**
```bash
# Check your inventory file
cat ansible/inventory/hosts | grep gns3-1
# Look for: gns3-1 ansible_host=YOUR_IP_HERE
```

**Option 2 - Terraform Output:**
```bash
# From terraform directory
cd terraform
terraform output | grep gns3
```

**Option 3 - Proxmox Web Interface:**
- Navigate to your GNS3 VM in Proxmox
- Check the "Summary" tab for IP address
- Or use "Console" and run `ip addr show`

**In the examples below, replace `<GNS3_IP>` with your actual GNS3 server IP address.**

### Pre-Deployment Verification

**Before deploying GNS3, verify your setup:**

#### Check Ansible Connectivity
```bash
# Test basic connectivity to GNS3 VMs
ansible gns3 -m ping

# Expected output: gns3-1 | SUCCESS => {"changed": false, "ping": "pong"}
```

**If ping fails:**
1. **Run bootstrap first** (if VM is new):
   ```bash
   # From terraform directory, get VM IP
   terraform output
   
   # Bootstrap the VM (creates ansible user)
   ansible-playbook -u ubuntu -kK playbooks/bootstrap.yml --limit gns3
   ```

2. **Test connectivity again**:
   ```bash
   ansible gns3 -m ping
   ```

### Deployment Steps

#### Step 1: Apply Foundation Configuration
```bash
# Navigate to ansible directory
cd ansible

# Apply foundation setup to GNS3 VMs
ansible-playbook --limit gns3 site.yml
```

Expected output: Foundation playbooks complete successfully on gns3-1.

#### Step 2: Deploy GNS3 Server
```bash
# Deploy GNS3 server
ansible-playbook playbooks/gns3.yml
```

Expected output:
- ✅ GNS3 packages installed from PPA
- ✅ GNS3 user created with KVM/libvirt permissions
- ✅ Configuration files deployed
- ✅ systemd service created and started
- ✅ Firewall rule added for port 3080
- ✅ API responding successfully

### Verification

**🎯 Primary Test - Web Interface Access**

1. **Open browser** to: `http://<GNS3_IP>:3080`
2. **Expected**: GNS3 web interface loads with project management screen
3. **Test functionality**:
   - Click "New Project" button
   - Enter test project name (e.g., "test-lab")
   - Verify project creation succeeds
   - Check project appears in project list

**✅ If the web interface works and you can create projects, GNS3 is successfully deployed!**

---

**Optional Command-Line Verification** *(for troubleshooting only)*:

#### 1. Service Status Check
```bash
# Quick check - GNS3 service is running
ansible gns3 -m shell -a "systemctl is-active gns3server"

# Expected output: "active"
```

#### 2. Network Connectivity Check  
```bash
# Modern approach (preferred)
ansible gns3 -m shell -a "ss -tlnp | grep 3080"

# Legacy approach (if ss not available)
ansible gns3 -m shell -a "netstat -tlnp | grep 3080"

# Expected output: tcp LISTEN 0.0.0.0:3080 or similar
```

#### 3. Firewall Verification
```bash
# Check firewall rules (requires sudo)
ansible gns3 -m shell -a "sudo ufw status numbered" --become

# Expected: Rule allowing 3080/tcp with comment "GNS3 Server Web Interface"
```

#### 4. API Verification
```bash
# Test GNS3 API endpoint (replace <GNS3_IP> with your server IP)
curl -s http://<GNS3_IP>:3080/v2/version | jq .

# Expected response:
# {
#   "version": "2.x.x",
#   "local": false
# }
```

### Configuration

GNS3 server uses these default configurations (customizable in `roles/gns3-server/defaults/main.yml`):

**Basic Settings:**
- **Web port**: 3080 (configurable via `gns3_listen_port`)
- **Projects path**: `/opt/gns3/projects`
- **Images path**: `/opt/gns3/images`
- **Authentication**: Disabled (suitable for internal lab use)

**Performance Settings:**
- **Log level**: INFO
- **Max concurrent projects**: 10
- **Console binding**: Enabled

**Security:**
- **Firewall**: Port 3080 opened automatically
- **User isolation**: Dedicated `gns3` user with minimal permissions
- **CORS**: Disabled (internal network only)

### Troubleshooting

#### Service Won't Start
```bash
# Quick service status check
ansible gns3 -m shell -a "systemctl is-active gns3server"

# If not active, check why
ansible gns3 -m shell -a "systemctl status gns3server --no-pager -l"

# Check recent logs
ansible gns3 -m shell -a "journalctl -u gns3server -n 10 --no-pager"

# Manually start service if needed
ansible gns3 -m shell -a "sudo systemctl start gns3server" --become

# Check configuration file
ansible gns3 -m shell -a "cat /etc/gns3/gns3_server.conf"
```

#### Web Interface Not Accessible
```bash
# First - is service running?
ansible gns3 -m shell -a "systemctl is-active gns3server"

# Check if port is listening
ansible gns3 -m shell -a "ss -tln | grep :3080"

# Check firewall rules
ansible gns3 -m shell -a "sudo ufw status | grep 3080" --become

# Test API from server itself
ansible gns3 -m shell -a "curl -s http://localhost:3080/v2/version"

# Test from your workstation (replace <GNS3_IP> with your server IP)
curl -s http://<GNS3_IP>:3080/v2/version
```

#### KVM/Virtualization Issues  
```bash
# Check KVM module is loaded
ansible gns3 -m shell -a "lsmod | grep kvm"

# Verify libvirt is running
ansible gns3 -m shell -a "systemctl status libvirtd"

# Test user permissions
ansible gns3 -m shell -a "sudo -u gns3 virsh list --all"
```

#### Common Log Messages
- **"Permission denied"** - Check gns3 user is in kvm,libvirt groups
- **"Port already in use"** - Another service using port 3080
- **"Cannot connect to libvirt"** - libvirtd service not running

### Adding GNS3 Images

After successful deployment, add network device images:

```bash
# SSH to GNS3 server (replace <GNS3_IP> with your server IP)
ssh ansible@<GNS3_IP>

# Switch to gns3 user
sudo su - gns3

# Create directories for different image types
mkdir -p /opt/gns3/images/{ios,qemu,docker}

# Download and place images in appropriate directories
# Note: Ensure you have proper licensing for any commercial images
```

### Multi-GNS3 Server Setup

For future expansion to multiple GNS3 servers:

1. **Update inventory**: Uncomment `gns3-2 ansible_host=192.168.1.232` in `inventory/hosts`
2. **Deploy second server**: `ansible-playbook --limit gns3-2 site.yml && ansible-playbook --limit gns3-2 playbooks/gns3.yml`
3. **Load balancing**: Configure Traefik proxy to distribute load between servers

---

## DNS Server Deployment

*[Coming next - BIND DNS infrastructure setup]*

---

## Monitoring Stack Deployment  

*[Coming next - Prometheus and Grafana setup]*

---

## Docker Hosts Deployment

*[Coming next - Container platform configuration]*

---

## Traefik Proxy Deployment

*[Coming next - Reverse proxy and load balancer]*

---

## Best Practices

### Deployment Order
1. **Network Infrastructure** - DNS, GNS3
2. **Application Platform** - Docker hosts  
3. **Monitoring** - Prometheus, Grafana
4. **Proxy/Load Balancer** - Traefik (last, as it routes to other services)

### Testing Strategy
- **Always test foundation first** - `ansible-playbook --limit [group] site.yml`
- **Verify each service individually** - Use provided verification commands
- **Test integration points** - Ensure services can communicate as needed
- **Document any customizations** - Note changes from default configurations

### Maintenance
- **Regular updates** - Run `ansible-playbook --limit [group] playbooks/system_updates.yml`
- **Security audits** - Periodic review of firewall rules and access
- **Backup configurations** - Version control all service configurations
- **Monitor resources** - Check CPU, memory, disk usage on service VMs

## Support

### Documentation References
- **[Ansible Setup](ansible-setup.md)** - Foundation configuration details
- **[Terraform Configuration](terraform-configuration.md)** - Infrastructure provisioning
- **[Getting Started](getting-started.md)** - Project overview and workflow

### Service-Specific Resources
- **GNS3 Documentation**: https://docs.gns3.com/
- **Troubleshooting**: Check service logs with `journalctl -u [service-name]`
- **Community Support**: Service-specific community forums and documentation