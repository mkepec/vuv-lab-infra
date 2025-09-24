# DNS Configuration Data

This directory contains data-driven DNS configuration files for the VUV Lab infrastructure. These YAML files define DNS zones, records, and Pi-hole policies that are automatically deployed by Ansible.

## Directory Structure

```
dns-config/
├── zones/                  # DNS zone definitions
│   ├── vuv.lab.yml        # Main domain zone
│   └── reverse-zones.yml  # Reverse DNS zones
├── pihole/                # Pi-hole configuration
│   └── blocklists.yml     # Ad blocking and filtering lists
├── environments/          # Environment-specific settings
│   ├── production.yml     # Production environment
│   └── development.yml    # Development environment
└── README.md             # This file
```

## Configuration Files

### zones/vuv.lab.yml
Defines all DNS records for the `vuv.lab` domain including:
- Infrastructure services (dns-bind, dns-pihole, ca, proxmox)
- Network services (gns3, traefik)
- Monitoring stack (prometheus, grafana) 
- Container hosts (docker-host-01)
- Service aliases (CNAME records)
- TXT and MX records

### zones/reverse-zones.yml
Defines PTR records for reverse DNS lookups on the 192.168.1.0/24 network.

### pihole/blocklists.yml
Configures Pi-hole ad blocking including:
- Essential blocklists (StevenBlack, malware domains)
- Privacy protection (tracking, ads)
- Educational institution options
- Custom whitelist and blacklist entries

### environments/
Environment-specific overrides:
- **production.yml**: Uses CARNet DNS servers, full security
- **development.yml**: Uses public DNS servers, relaxed security

## Usage

These configuration files are automatically loaded by the `dns-configuration` Ansible role:

```bash
# Deploy all DNS configuration
ansible-playbook dns-configuration.yml

# Deploy specific environment
ansible-playbook dns-configuration.yml -e dns_environment=development

# Deploy only zone updates
ansible-playbook dns-configuration.yml --tags=bind-zones
```

## Adding New Services

To add a new service to DNS:

1. **Edit zones/vuv.lab.yml**:
   ```yaml
   - name: "newservice"
     type: "A"
     value: "192.168.1.50"
     comment: "New service description"
   ```

2. **Edit zones/reverse-zones.yml**:
   ```yaml
   - ip_suffix: "50"
     hostname: "newservice.vuv.lab"
     comment: "New service"
   ```

3. **Deploy changes**:
   ```bash
   ansible-playbook dns-configuration.yml
   ```

## GitOps Workflow

DNS changes follow GitOps principles:

1. **Create branch**: `git checkout -b feature/add-service-dns`
2. **Edit config files**: Modify YAML files in this directory
3. **Commit changes**: `git commit -m "Add DNS records for new service"`
4. **Create PR**: Submit for peer review
5. **Deploy**: After merge, run `ansible-playbook dns-configuration.yml`

## Validation

The `dns-configuration` role includes automatic validation:
- DNS record syntax checking
- IP address format validation
- Duplicate record detection
- Zone file syntax verification
- Live DNS resolution testing

## Best Practices

1. **Always add comments** to DNS records
2. **Follow IP allocation** scheme (see network documentation)
3. **Test in development** before production deployment
4. **Use meaningful names** for services
5. **Keep configurations in sync** between forward and reverse zones

## IP Address Allocation

Current allocation scheme:
- `.1-9`: Network infrastructure (gateway, etc.)
- `.10-19`: DNS and core services
- `.20-29`: Network simulation (GNS3)
- `.30-39`: Monitoring services
- `.40-49`: Container hosts
- `.50-99`: Application services
- `.100-149`: Development/test services
- `.150-189`: Reserved
- `.190-199`: Physical infrastructure (Proxmox)