# Service Deployment Overview

This guide provides the framework for deploying specific services on VUV Lab Infrastructure after completing the **[Ansible setup foundation](ansible-setup.md)**.

## Prerequisites

Before deploying services, ensure you have completed:

- ✅ **[Proxmox Setup](proxmox-setup.md)** - Hypervisor with templates ready
- ✅ **[Terraform Configuration](terraform-configuration.md)** - Infrastructure provisioning working
- ✅ **[Ansible Setup](ansible-setup.md)** - Foundation playbooks tested and working

## Service Deployment Pattern

Each service deployment follows this proven pattern:

### Phase 1: Infrastructure Provisioning
```bash
# Navigate to Terraform
cd terraform

# Plan and apply infrastructure changes
terraform plan
terraform apply
```

### Phase 2: Service Configuration  
```bash
# Navigate to Ansible
cd ../ansible

# Run foundation setup (if new VMs)
ansible-playbook site.yml --limit new-service-group

# Deploy specific service
ansible-playbook playbooks/deploy-[service].yml
```

### Phase 3: Integration Testing
```bash
# Verify service is accessible
ansible [service-group] -m uri -a "url=http://{{ ansible_host }}:[port]"

# Test service-specific functionality
ansible-playbook playbooks/test-[service].yml
```

## Available Service Deployments

### Network Infrastructure
- **[GNS3 Server](gns3-deployment.md)** - Network simulation platform for lab exercises
- **[DNS Server](dns-deployment.md)** - BIND DNS for internal name resolution

### Application Platform  
- **[Docker Hosts](docker-deployment.md)** - Container platform for microservices
- **[Traefik Proxy](traefik-deployment.md)** - Reverse proxy and load balancer

### Monitoring & Operations
- **[Monitoring Stack](monitoring-deployment.md)** - Prometheus and Grafana for observability

## Service Architecture Principles

### Inventory Organization
Services are organized in logical groups:

```ini
# Network Infrastructure
[dns]
dns-server ansible_host=192.168.1.10

[gns3]  
gns3-1 ansible_host=192.168.1.231
gns3-2 ansible_host=192.168.1.232  # Future expansion

# Application Platform
[docker_hosts]
docker-host-01 ansible_host=192.168.1.40
docker-host-02 ansible_host=192.168.1.41

# Monitoring
[monitoring]
prometheus ansible_host=192.168.1.30
grafana ansible_host=192.168.1.31

# Service Groups
[network_infrastructure:children]
dns
gns3

[application_platform:children]
docker_hosts

[operations:children]
monitoring
```

### Firewall Management
- **Foundation security** applied to all VMs via `security_hardening.yml`
- **Service-specific rules** added by each service deployment playbook
- **Idempotent and additive** - safe to re-run without conflicts

Example service firewall rules:
```yaml
# In gns3-deployment.yml
- name: Allow GNS3 web interface
  ufw:
    rule: allow
    port: 3080
    proto: tcp
    comment: "GNS3 Web Interface"
```

### Role-Based Organization
Services use Ansible roles for reusability:

```
ansible/roles/
├── gns3/              # GNS3 server configuration
├── bind-dns/          # DNS server setup
├── docker-host/       # Docker engine installation
├── prometheus/        # Metrics collection
├── grafana/          # Monitoring dashboards
└── traefik/          # Reverse proxy setup
```

### Variable Management
Service configuration centralized in `group_vars/`:

```
ansible/group_vars/
├── all.yml            # Global settings
├── gns3.yml          # GNS3-specific configuration  
├── dns.yml           # DNS zone configuration
├── monitoring.yml    # Monitoring settings
└── docker_hosts.yml  # Container platform config
```

## Deployment Workflows

### Single Service Deployment
```bash
# Deploy only GNS3 servers
ansible-playbook --limit gns3 site.yml
ansible-playbook playbooks/deploy-gns3.yml

# Deploy only monitoring stack  
ansible-playbook --limit monitoring site.yml
ansible-playbook playbooks/deploy-monitoring.yml
```

### Complete Environment Deployment
```bash
# Deploy entire lab infrastructure
ansible-playbook site.yml                    # Foundation on all VMs
ansible-playbook playbooks/deploy-dns.yml    # DNS infrastructure
ansible-playbook playbooks/deploy-gns3.yml   # Network simulation
ansible-playbook playbooks/deploy-monitoring.yml  # Observability
```

### Development Workflow
```bash
# Test deployment on single VM
ansible-playbook --limit gns3-1 --check playbooks/deploy-gns3.yml

# Apply to test environment first
ansible-playbook --limit test playbooks/deploy-gns3.yml

# Deploy to production after validation
ansible-playbook --limit gns3 playbooks/deploy-gns3.yml
```

## Best Practices

### Service Development
1. **Start with roles** - Use `ansible-galaxy init roles/service-name`
2. **Test individually** - Validate each service independently  
3. **Document thoroughly** - Include service-specific documentation
4. **Version control** - All service configurations in Git

### Integration Guidelines
1. **Preserve foundation** - Don't modify core security settings
2. **Add firewall rules** - Never remove existing UFW rules
3. **Use standard ports** - Follow common service port conventions
4. **Enable monitoring** - Expose metrics endpoints where possible

### University Handover
1. **Clear documentation** - Each service has deployment guide
2. **Standard patterns** - Consistent approach across all services
3. **Troubleshooting guides** - Common issues and solutions
4. **Maintenance procedures** - Regular operation tasks

## Next Steps

Ready to deploy your first service? Start with:

1. **[GNS3 Server Deployment](gns3-deployment.md)** - Core network simulation platform
2. **[DNS Server Deployment](dns-deployment.md)** - Essential infrastructure service

Each service guide includes:
- Infrastructure requirements
- Step-by-step deployment instructions  
- Configuration examples
- Testing and validation procedures
- Troubleshooting guidance

## Reference

### Related Documentation
- **[Ansible Setup](ansible-setup.md)** - Foundation configuration
- **[Terraform Configuration](terraform-configuration.md)** - Infrastructure provisioning
- **[Getting Started](getting-started.md)** - Project overview

### Support Resources
- **Ansible Documentation**: https://docs.ansible.com/
- **Service-specific guides**: Individual deployment documentation
- **Troubleshooting**: Common issues and solutions in each service guide