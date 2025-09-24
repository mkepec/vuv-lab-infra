# DNS Infrastructure Guide

This guide covers the DNS infrastructure deployment and management for VUV Lab. The solution provides enterprise-grade DNS services with educational value, operational simplicity, and GitOps automation.

## How to Use This Guide

This DNS infrastructure guide is part of the complete VUV Lab Infrastructure deployment process:

1. **[Getting Started](getting-started.md)** - Overview and prerequisites ✅
2. **[Proxmox Setup](proxmox-setup.md)** - Hypervisor configuration ✅  
3. **[Terraform Configuration](terraform-configuration.md)** - Infrastructure provisioning ✅
4. **[Ansible Setup](ansible-setup.md)** - Configuration management ✅
5. **👉 DNS Infrastructure** - DNS services deployment (this guide)
6. **Certificate Authority Setup** - PKI and certificate management
7. **Service Deployment** - Deploy remaining services (GNS3, monitoring, etc.)

> 💡 **Previous Step**: Ensure you have completed **[Ansible Setup](ansible-setup.md)** before proceeding. You need a working Ansible environment to deploy DNS services.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Why This DNS Design](#why-this-dns-design)
- [Components and Roles](#components-and-roles)
- [Implementation Details](#implementation-details)
- [Deployment Guide](#deployment-guide)
- [Administration and GitOps](#administration-and-gitops)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## Architecture Overview

The VUV Lab DNS infrastructure uses a **hybrid BIND + Pi-hole architecture** deployed in **LXC containers** with **data-driven configuration** and **GitOps workflows**.

### DNS Request Flow
```
Lab VMs → BIND (Primary DNS) → Pi-hole (Filter) → CARNet DNS → Internet
        ↓
    Authoritative for vuv.lab domain
        ↓
    Forwards external queries to Pi-hole
        ↓
    Pi-hole filters ads/malware
        ↓
    Clean queries forwarded to CARNet
```

### Network Architecture
```
┌─────────────────────────────────────────────┐
│                Proxmox Host                 │
│  ┌─────────────┐    ┌─────────────────────┐ │
│  │ BIND LXC    │    │ Pi-hole LXC         │ │
│  │ 192.168.1.10│────▶│ 192.168.1.11        │ │
│  │ Port 53     │    │ Port 53 + Web UI    │ │
│  │ (vuv.lab)   │    │ (Filtering)         │ │
│  └─────────────┘    └─────────────────────┘ │
└─────────────────────────────────────────────┘
              ▲                      │
              │                      ▼
    ┌─────────────────┐    ┌─────────────────┐
    │   Lab VMs       │    │ CARNet DNS      │
    │ DNS: 192.168.1.10│   │ 161.53.72.1     │
    │ Fallback: CARNet │    │ (Upstream)      │
    └─────────────────┘    └─────────────────┘
```

## Why This DNS Design

### Educational Institution Requirements

**Learning Objectives**:
- Students understand enterprise DNS architecture (BIND)
- Hands-on experience with zone files and DNS management
- Real-world DNS security and filtering concepts
- GitOps workflows for infrastructure management

**Operational Requirements**:
- Easy management for university IT staff (Pi-hole web interface)
- Reliable service with minimal maintenance overhead
- Network protection (ad blocking, malware filtering)
- Integration with existing CARNet infrastructure

### Design Benefits

✅ **Educational Value**: BIND provides industry-standard DNS learning  
✅ **Operational Ease**: Pi-hole web interface for daily management  
✅ **Security**: DNS filtering protects lab network from malware/ads  
✅ **Reliability**: Multiple failover layers (BIND → Pi-hole → CARNet)  
✅ **Resource Efficiency**: LXC containers minimize resource usage  
✅ **GitOps Ready**: All configuration version-controlled and automated  
✅ **Scalable**: Can easily add more DNS servers or features  

### Comparison with Alternatives

| Approach | Learning Value | Ease of Use | Features | Maintenance |
|----------|---------------|-------------|----------|-------------|
| **Pi-hole Only** | Low | High | Basic DNS + Filtering | Low |
| **BIND Only** | High | Low | Full DNS Features | High |
| **BIND + Pi-hole** | High | High | Full DNS + Filtering | Medium |

**Selected**: BIND + Pi-hole provides the best balance for educational institutions.

## Components and Roles

### 1. BIND DNS Server (192.168.1.10)

**Role**: Authoritative DNS server for `vuv.lab` domain

**Responsibilities**:
- Hosts DNS zones for lab infrastructure (`vuv.lab`)
- Provides A, CNAME, PTR, TXT records for all lab services
- Handles reverse DNS lookups (192.168.1.0/24)
- Forwards non-local queries to Pi-hole for filtering
- DNS caching for improved performance
- DNS query logging for monitoring

**Key Features**:
- Industry-standard BIND9 software
- Zone files managed via Ansible and Git
- Security hardening (rate limiting, access controls)
- Comprehensive logging and monitoring

### 2. Pi-hole DNS Filter (192.168.1.11)

**Role**: DNS filtering and ad blocking service

**Responsibilities**:
- Filters malicious domains and advertisements
- Provides web-based management interface
- Forwards clean queries to CARNet DNS servers
- DNS caching for external queries
- Network-wide protection for all lab devices
- Query logging and analytics

**Key Features**:
- User-friendly web dashboard at `http://192.168.1.11/admin`
- Configurable blocklists (ads, malware, tracking)
- Custom whitelist/blacklist management
- Integration with upstream DNS providers
- Statistics and query monitoring

### 3. Data-Driven Configuration

**Role**: Version-controlled DNS configuration management

**Structure**:
```
dns-config/
├── zones/
│   ├── vuv.lab.yml        # Main domain records
│   └── reverse-zones.yml  # PTR records
├── pihole/
│   └── blocklists.yml     # Filtering policies
└── environments/
    ├── production.yml     # CARNet DNS
    └── development.yml    # Public DNS
```

**Benefits**:
- All DNS changes tracked in Git
- Peer review via pull requests
- Environment-specific configurations
- Automated validation and deployment
- Easy rollback of changes

### 4. Ansible Automation

**Architecture**: Two-role separation of concerns

**dns-infrastructure role**:
- Provisions LXC containers on Proxmox
- Installs and configures BIND9 software
- Installs and configures Pi-hole software
- Sets up networking and security
- Base configuration only (no specific DNS records)

**dns-configuration role**:
- Deploys DNS zones from YAML data
- Updates Pi-hole policies and blocklists
- Validates DNS configuration syntax
- Tests live DNS resolution
- Generates deployment reports

## Implementation Details

### LXC Container Specifications

**BIND Container (`dns-bind`)**:
- VMID: 110
- IP: 192.168.1.10/24
- Resources: 1 CPU, 1GB RAM, 8GB storage
- OS: Ubuntu 22.04 LTS
- Services: bind9, rsyslog, ufw

**Pi-hole Container (`dns-pihole`)**:
- VMID: 111  
- IP: 192.168.1.11/24
- Resources: 1 CPU, 1GB RAM, 8GB storage
- OS: Ubuntu 22.04 LTS
- Services: pihole-FTL, lighttpd, ufw

### DNS Zone Configuration

**Forward Zone (`vuv.lab`)**:
```yaml
records:
  - name: "dns-bind"
    type: "A"
    value: "192.168.1.10"
    
  - name: "grafana" 
    type: "A"
    value: "192.168.1.31"
    
  - name: "monitoring"
    type: "CNAME"
    value: "grafana"
```

**Reverse Zone (`1.168.192.in-addr.arpa`)**:
```yaml
ptr_records:
  - ip_suffix: "10"
    hostname: "dns-bind.vuv.lab"
    
  - ip_suffix: "31"  
    hostname: "grafana.vuv.lab"
```

### Security Configuration

**BIND Security**:
- Query ACLs limited to lab network (192.168.1.0/24)
- Rate limiting to prevent DNS amplification attacks
- Version and hostname hiding
- Recursive queries only from trusted networks
- Zone transfers disabled

**Pi-hole Security**:
- Web interface restricted to lab network
- UFW firewall enabled with specific rules
- Regular blocklist updates
- Query logging for security monitoring

**Network Security**:
- LXC containers isolated from host
- Static IP assignments
- Dedicated VLAN support (if configured)
- CARNet DNS as fallback for reliability

## Deployment Guide

### Prerequisites

Before deploying DNS infrastructure:

1. ✅ **Proxmox VE configured** with API access and templates
2. ✅ **Ansible working** with ssh key authentication to target systems
3. ✅ **Network connectivity** between management workstation and Proxmox
4. ✅ **DNS resolution** currently working (for downloading packages)

### Step 1: Prepare Environment

1. **Navigate to ansible directory**:
   ```bash
   cd /path/to/vuv-lab-infra/ansible
   ```

2. **Verify Proxmox API access**:
   ```bash
   # Test Proxmox connectivity
   curl -k https://192.168.1.190:8006/api2/json/version
   ```

3. **Configure vault secrets**:
   ```bash
   # Create or edit vault file
   ansible-vault create group_vars/all/vault.yml
   
   # Add Proxmox API token:
   vault_proxmox_api_token: "your-proxmox-api-token-here"
   vault_pihole_password: "your-pihole-admin-password"
   ```

### Step 2: Validate Configuration

1. **Review DNS configuration data**:
   ```bash
   # Check DNS zone configuration
   cat dns-config/zones/vuv.lab.yml
   
   # Check Pi-hole configuration  
   cat dns-config/pihole/blocklists.yml
   
   # Check environment settings
   cat dns-config/environments/production.yml
   ```

2. **Validate Ansible configuration**:
   ```bash
   # Check Ansible syntax
   ansible-playbook --syntax-check playbooks/dns-complete.yml
   
   # Dry run (check mode)
   ansible-playbook --check playbooks/dns-complete.yml
   ```

### Step 3: Deploy DNS Infrastructure

Choose one of three deployment approaches:

#### Option A: Complete Deployment (Recommended)
```bash
# Deploy complete DNS infrastructure with validation
ansible-playbook playbooks/dns-complete.yml
```

#### Option B: Staged Deployment
```bash
# Step 1: Deploy LXC containers and software
ansible-playbook playbooks/dns-infrastructure.yml

# Step 2: Deploy DNS configuration and records
ansible-playbook playbooks/dns-configuration.yml
```

#### Option C: Integrated Site Deployment
```bash
# Deploy as part of complete site configuration
ansible-playbook site.yml -e deploy_dns=true
```

### Step 4: Verify Deployment

1. **Check container status**:
   ```bash
   # From Proxmox host or web interface
   pct list | grep dns
   pct status 110  # BIND container
   pct status 111  # Pi-hole container
   ```

2. **Test DNS resolution**:
   ```bash
   # Test local domain resolution
   dig @192.168.1.10 dns-bind.vuv.lab
   
   # Test external resolution
   dig @192.168.1.10 google.com
   
   # Test Pi-hole filtering
   dig @192.168.1.11 doubleclick.net
   ```

3. **Access web interfaces**:
   - **Pi-hole Admin**: http://192.168.1.11/admin
   - **Proxmox**: https://192.168.1.190:8006

### Step 5: Configure Lab VMs

Update lab VMs to use the new DNS infrastructure:

**Ubuntu/Debian VMs**:
```bash
# Edit netplan configuration
sudo nano /etc/netplan/01-netcfg.yaml

# Add DNS configuration:
network:
  ethernets:
    eth0:
      nameservers:
        addresses:
          - 192.168.1.10    # BIND DNS
          - 161.53.72.1     # CARNet fallback

# Apply changes
sudo netplan apply
```

**Test from lab VM**:
```bash
# Test local resolution
nslookup grafana.vuv.lab

# Test external resolution
nslookup google.com

# Check current DNS
cat /etc/resolv.conf
```

## Administration and GitOps

### GitOps Workflow

DNS configuration follows GitOps principles for all changes:

```mermaid
graph LR
    A[Update YAML] --> B[Create Branch]
    B --> C[Commit Changes]
    C --> D[Create PR]
    D --> E[Peer Review]
    E --> F[Merge to Main]
    F --> G[Deploy Changes]
    G --> H[Validate DNS]
```

### Common Administrative Tasks

#### Adding New Services

1. **Create feature branch**:
   ```bash
   git checkout -b feature/add-jenkins-dns
   ```

2. **Update DNS configuration**:
   ```bash
   # Edit zones/vuv.lab.yml
   nano ansible/dns-config/zones/vuv.lab.yml
   
   # Add new record:
   - name: "jenkins"
     type: "A"
     value: "192.168.1.50"
     comment: "Jenkins CI/CD Server"
   ```

3. **Update reverse DNS**:
   ```bash
   # Edit zones/reverse-zones.yml  
   nano ansible/dns-config/zones/reverse-zones.yml
   
   # Add PTR record:
   - ip_suffix: "50"
     hostname: "jenkins.vuv.lab"
     comment: "Jenkins CI/CD"
   ```

4. **Commit and create PR**:
   ```bash
   git add ansible/dns-config/
   git commit -m "Add DNS records for Jenkins CI/CD server"
   git push origin feature/add-jenkins-dns
   
   # Create pull request for peer review
   ```

5. **Deploy after PR merge**:
   ```bash
   git checkout main
   git pull origin main
   
   # Deploy DNS configuration changes
   cd ansible
   ansible-playbook playbooks/dns-configuration.yml
   ```

6. **Validate deployment**:
   ```bash
   # Test new DNS record
   dig @192.168.1.10 jenkins.vuv.lab
   nslookup jenkins.vuv.lab 192.168.1.10
   ```

#### Updating Pi-hole Policies

1. **Edit blocklist configuration**:
   ```bash
   nano ansible/dns-config/pihole/blocklists.yml
   
   # Add new blocklist:
   - name: "Custom Education Blocklist"
     url: "https://example.com/education-blocklist.txt"
     enabled: true
     comment: "Block distracting sites during class"
   ```

2. **Update whitelist**:
   ```yaml
   pihole_whitelist:
     - "carnet.hr"
     - "vuv.hr"
     - "newsite.edu"  # Add new whitelist entry
   ```

3. **Deploy changes**:
   ```bash
   ansible-playbook playbooks/dns-configuration.yml --tags=pihole-config
   ```

#### Environment-Specific Changes

1. **Update development environment**:
   ```bash
   nano ansible/dns-config/environments/development.yml
   
   # Add development-specific settings
   development_dns_records:
     - name: "test-api"
       type: "A"
       value: "192.168.1.100"
   ```

2. **Deploy to development**:
   ```bash
   ansible-playbook playbooks/dns-configuration.yml -e dns_environment=development
   ```

#### Configuration Rollback

1. **Identify problematic commit**:
   ```bash
   git log --oneline ansible/dns-config/
   ```

2. **Revert specific changes**:
   ```bash
   git revert <commit-hash>
   git push origin main
   ```

3. **Redeploy configuration**:
   ```bash
   ansible-playbook playbooks/dns-configuration.yml
   ```

### Monitoring and Maintenance

#### Regular Maintenance Tasks

**Weekly**:
- Review Pi-hole query logs for anomalies
- Check DNS service status and resource usage
- Update Pi-hole blocklists if needed

**Monthly**:
- Review and update DNS records for accuracy
- Check BIND log files for errors or security issues
- Validate backup and disaster recovery procedures

**Quarterly**:
- Review and update Pi-hole whitelist/blacklist
- Assess DNS performance and optimize if needed
- Update documentation and procedures

#### Monitoring Commands

```bash
# Check service status
ansible all -m shell -a "systemctl status bind9" --limit=dns-bind
ansible all -m shell -a "systemctl status pihole-FTL" --limit=dns-pihole

# Check DNS resolution
ansible all -m shell -a "dig @192.168.1.10 vuv.lab"

# Check resource usage
ansible all -m shell -a "free -h && df -h" --limit=dns*

# Review logs
ansible all -m shell -a "tail -20 /var/log/bind/queries.log" --limit=dns-bind
ansible all -m shell -a "tail -20 /var/log/pihole.log" --limit=dns-pihole
```

#### Performance Monitoring

Monitor DNS performance with these commands:

```bash
# DNS query response times
dig @192.168.1.10 +stats google.com

# Pi-hole statistics
curl -s http://192.168.1.11/admin/api.php?summaryRaw

# BIND statistics
rndc stats
cat /var/cache/bind/named.stats
```

## Troubleshooting

### Common Issues and Solutions

#### DNS Resolution Failures

**Symptom**: Cannot resolve vuv.lab domains
```bash
dig @192.168.1.10 grafana.vuv.lab
# Returns NXDOMAIN or timeout
```

**Diagnosis**:
```bash
# Check BIND service status
ansible all -m shell -a "systemctl status bind9" --limit=dns-bind

# Check BIND configuration syntax  
ansible all -m shell -a "named-checkconf" --limit=dns-bind

# Check zone file syntax
ansible all -m shell -a "named-checkzone vuv.lab /etc/bind/zones/vuv.lab" --limit=dns-bind
```

**Solutions**:
1. Restart BIND service: `systemctl restart bind9`
2. Fix configuration syntax errors
3. Reload configuration: `rndc reload`

#### Pi-hole Not Filtering

**Symptom**: Ads and malicious sites not blocked

**Diagnosis**:
```bash
# Check Pi-hole service status
curl -s http://192.168.1.11/admin/api.php?status

# Check gravity database
ansible all -m shell -a "ls -la /etc/pihole/gravity.db" --limit=dns-pihole

# Test blocking
dig @192.168.1.11 doubleclick.net
```

**Solutions**:
1. Update gravity database: `pihole -g`
2. Restart Pi-hole FTL: `systemctl restart pihole-FTL`
3. Check blocklist URLs are accessible

#### LXC Container Issues

**Symptom**: Containers not starting or accessible

**Diagnosis**:
```bash
# Check container status (on Proxmox host)
pct list
pct status 110 111

# Check resource usage
pct config 110
pct config 111
```

**Solutions**:
1. Start containers: `pct start 110 && pct start 111`
2. Check resource limits and adjust if needed
3. Verify network connectivity

#### Configuration Deployment Failures

**Symptom**: Ansible playbooks fail during deployment

**Common Causes**:
- Containers not accessible via SSH
- Insufficient disk space
- Network connectivity issues
- Permission problems

**Debugging Steps**:
```bash
# Test SSH connectivity
ansible all -m ping --limit=dns*

# Check available resources
ansible all -m shell -a "df -h" --limit=dns*
ansible all -m shell -a "free -h" --limit=dns*

# Run with verbose output
ansible-playbook -vvv playbooks/dns-configuration.yml
```

### DNS Query Troubleshooting

#### Testing DNS Resolution Chain

```bash
# Test each component in the chain
# 1. Test BIND directly
dig @192.168.1.10 vuv.lab

# 2. Test Pi-hole directly  
dig @192.168.1.11 google.com

# 3. Test CARNet DNS directly
dig @161.53.72.1 google.com

# 4. Test full chain from lab VM
dig grafana.vuv.lab
```

#### Analyzing DNS Logs

```bash
# BIND query logs
tail -f /var/log/bind/queries.log

# Pi-hole query logs
tail -f /var/log/pihole.log

# System logs
journalctl -u bind9 -f
journalctl -u pihole-FTL -f
```

### Performance Issues

#### High DNS Query Latency

**Diagnosis**:
```bash
# Measure query response times
time dig @192.168.1.10 google.com
time dig @192.168.1.11 google.com

# Check cache hit rates
rndc dumpdb -cache
grep "cache DB dump" /var/log/bind/general.log
```

**Solutions**:
1. Increase cache size in BIND configuration
2. Optimize Pi-hole blocklists (remove slow sources)
3. Consider additional DNS servers for load balancing

#### Resource Exhaustion

**Diagnosis**:
```bash
# Check memory usage
free -h

# Check disk usage
df -h

# Check DNS process resource usage
top -p $(pgrep named)
top -p $(pgrep pihole-FTL)
```

**Solutions**:
1. Increase LXC container memory allocation
2. Implement log rotation for large log files
3. Clean up temporary files and caches

## Next Steps

### Immediate Next Steps

After successful DNS deployment:

1. **🧪 Test DNS Resolution**: Verify all lab VMs can resolve vuv.lab domains
2. **🔧 Configure Remaining VMs**: Update DNS settings on all lab systems
3. **📊 Monitor Performance**: Check DNS query logs and Pi-hole analytics
4. **📝 Document Custom Changes**: Record any site-specific customizations

### Continue Infrastructure Deployment

**Next Guide**: **[Certificate Authority Setup](ca-infrastructure-guide.md)**

The Certificate Authority will integrate with DNS to provide:
- HTTPS certificates for all lab services
- Trusted certificate distribution
- Automated certificate management via ACME
- Integration with Traefik reverse proxy

### Future Enhancements

Consider these enhancements after basic DNS is operational:

**High Availability**:
- Deploy secondary DNS servers
- Configure BIND zone transfers
- Implement DNS load balancing

**Advanced Features**:
- Dynamic DNS updates via API
- DNS-over-HTTPS (DoH) support
- Integration with monitoring systems
- Automated failover mechanisms

**Security Enhancements**:
- DNSSEC implementation
- DNS query analytics and threat detection
- Integration with security monitoring tools

## Related Documentation

### VUV Lab Infrastructure Guides
- **[Getting Started](getting-started.md)** - Project overview and prerequisites
- **[Proxmox Setup](proxmox-setup.md)** - Hypervisor configuration  
- **[Terraform Configuration](terraform-configuration.md)** - Infrastructure provisioning
- **[Ansible Setup](ansible-setup.md)** - Configuration management foundation
- **[Certificate Authority Guide](ca-infrastructure-guide.md)** - PKI and certificate management
- **[Service Deployment Guide](services-deployment.md)** - Deploy remaining services

### Technical References
- **Configuration Files**: `ansible/dns-config/` directory
- **Ansible Roles**: `ansible/roles/dns-*` directories
- **Deployment Playbooks**: `ansible/playbooks/dns-*.yml`
- **Deployment Reports**: Generated during ansible runs

### External Resources
- **[BIND 9 Administrator Reference Manual](https://bind9.readthedocs.io/)** - Official BIND documentation
- **[Pi-hole Documentation](https://docs.pi-hole.net/)** - Pi-hole configuration and management
- **[Ansible Documentation](https://docs.ansible.com/)** - Ansible automation platform
- **[Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)** - Proxmox virtualization platform

---

*This DNS infrastructure provides the foundation for all other VUV Lab services. The combination of educational value (BIND) and operational simplicity (Pi-hole) makes it ideal for university environments while maintaining enterprise-grade capabilities.*