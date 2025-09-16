# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Infrastructure as Code (IaC) repository for VUV (Virovitica University of Applied Sciences) laboratory infrastructure. The project aims to standardize and automate the setup of a computer laboratory environment running on Dell PowerEdge R530 with Proxmox VE hypervisor.

## Commands

### Initial Setup (when directories are created)
```bash
# Terraform operations
cd terraform
terraform init
terraform plan
terraform apply
terraform destroy  # Use with caution

# Ansible operations  
cd ansible
ansible-playbook site.yml
ansible-playbook --check site.yml  # Dry run
```

## Architecture

### Technology Stack
- **Infrastructure Provisioning**: Terraform >= 1.5
- **Configuration Management**: Ansible >= 2.15  
- **Virtualization Platform**: Proxmox VE 9
- **Hardware**: Dell PowerEdge R530 (Intel Xeon E5-2620 v3, 64GB RAM)

### Planned Directory Structure
```
vuv-lab-infra/
├── terraform/          # Infrastructure provisioning code
├── ansible/            # Configuration management playbooks
├── docs/               # Architecture decisions and procedures  
├── monitoring/         # Monitoring and alerting configurations
└── scripts/           # Utility and helper scripts
```

### Target Services
- GNS3 Server for network simulation
- Docker Host VMs for containerized services
- LXC Containers for lightweight virtualization
- DNS, NTP, monitoring, and firewall services

## Development Workflow

This project follows GitOps principles:
1. Create issues for infrastructure changes
2. Develop in feature branches
3. Submit pull requests for peer review
4. Test changes before production deployment
5. Monitor system behavior after changes

## Key Considerations

- This is an educational project demonstrating DevOps practices
- Designed for handover to university IT staff
- Focus on reproducible, version-controlled infrastructure
- All infrastructure should be documented and automated
- Security and operational excellence are priorities

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
