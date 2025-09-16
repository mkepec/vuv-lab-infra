# VUV Lab Infrastructure

Infrastructure as Code (IaC) setup for Virovitica University of Applied Sciences laboratory environment.

## Project Overview

This repository contains the infrastructure configuration and automation code for the VUV computer laboratory, built on a Dell PowerEdge R530 server running Proxmox VE. The project demonstrates modern DevOps practices including Infrastructure as Code, GitOps workflows, and automated configuration management.

## Goals and Objectives

### Primary Goals
- **Standardize** laboratory infrastructure setup and maintenance procedures
- **Automate** virtual machine and container provisioning using modern DevOps tools
- **Document** operational procedures for seamless handover to university IT staff
- **Demonstrate** DevOps best practices in an educational environment

### Educational Outcomes
- Provide hands-on experience with industry-standard infrastructure tools
- Enable university IT staff to learn and apply DevOps methodologies
- Create a reproducible, version-controlled infrastructure setup
- Establish operational excellence through automation and monitoring

## Infrastructure Architecture

### Hardware Foundation
- **Server**: Dell PowerEdge R530
- **CPU**: Intel Xeon E5-2620 v3 @ 2.40GHz (24 cores)
- **Memory**: 64GB RAM
- **Hypervisor**: Proxmox VE 9

### Planned Services
- **GNS3 Server** - Network simulation for networking courses
- **Docker Host VMs** - Container orchestration and development environments
- **LXC Containers** - Lightweight virtualization for various services
- **DNS Services** - Internal name resolution
- **Monitoring & Logging** - Infrastructure observability
- **Time Synchronization** - NTP services
- **Firewall** - Network security and segmentation

## Technology Stack

### Infrastructure as Code
- **[Terraform](https://terraform.io/)** - Infrastructure provisioning and management
- **[Ansible](https://ansible.com/)** - Configuration management and automation

### Virtualization Platform
- **[Proxmox VE](https://proxmox.com/)** - Open-source virtualization platform

### Development Practices
- **GitOps** - Git-based operational workflows
- **Infrastructure as Code (IaC)** - Version-controlled infrastructure
- **Automated Documentation** - Self-documenting infrastructure

## Prerequisites

### Required Software
- Proxmox VE 9 installed and configured on the Dell R530 server
- Terraform >= 1.5
- Ansible >= 2.15
- Git for version control

### Access Requirements
- Administrative access to Proxmox VE web interface
- SSH access to Proxmox host
- Network connectivity to the university's infrastructure

## Repository Structure

```
vuv-lab-infra/
├── terraform/          # Infrastructure provisioning
├── ansible/            # Configuration management
├── docs/               # Documentation and procedures
├── monitoring/         # Monitoring and alerting configs
└── scripts/           # Utility and helper scripts
```

## Quick Start

**Starting with a fresh Proxmox VE installation? Follow our step-by-step guides:**

1. **[Getting Started Guide](docs/getting-started.md)** - Complete setup from fresh Proxmox installation to working VM deployment
2. **[Proxmox Setup](docs/proxmox-setup.md)** - Detailed Proxmox VE preparation and user configuration
3. **[Terraform Configuration](docs/terraform-configuration.md)** - Infrastructure provisioning setup and examples
4. **[Validation & Testing](docs/validation-testing.md)** - Comprehensive testing procedures to ensure everything works

### Quick Validation Test

After completing the setup guides, test your infrastructure:

```bash
# Navigate to test workspace
cd terraform/test

# Initialize and deploy a test VM
terraform init
terraform plan
terraform apply

# Verify SSH access works
ssh -i ~/.ssh/proxmox_key ubuntu@<vm-ip> uptime

# Clean up test resources
terraform destroy
```

## Documentation

Comprehensive documentation is provided in the `/docs` directory:

- **Architecture Decisions** - Design choices and rationale
- **Operational Procedures** - Day-to-day maintenance tasks
- **Troubleshooting Guide** - Common issues and solutions
- **Backup and Recovery** - Data protection procedures
- **Security Guidelines** - Best practices and compliance

## Development Workflow

This project follows GitOps principles:

1. **Plan** - Create issues for infrastructure changes
2. **Code** - Develop infrastructure changes in feature branches
3. **Review** - Submit pull requests for peer review
4. **Test** - Validate changes in development environment
5. **Deploy** - Apply changes to production infrastructure
6. **Monitor** - Observe system behavior and performance

## Handover and Maintenance

### Knowledge Transfer
- Comprehensive documentation for university IT staff
- Training materials for Terraform and Ansible
- Operational runbooks for common tasks
- Emergency procedures and contacts

### Ongoing Support
- Regular maintenance schedules
- Update procedures for security patches
- Monitoring and alerting setup
- Backup verification processes

## Contributing

This project is maintained by external DevOps consultants in collaboration with VUV IT staff. For questions or contributions:

1. Create an issue for discussion
2. Fork the repository for changes
3. Submit pull requests for review
4. Follow the established coding standards

## Contact and Support

- **University Domain**: vuv.hr
- **Project Lead**: [To be filled]
- **IT Contact**: [University IT Department]

## License

[To be determined based on university policies]

---

*This project demonstrates modern Infrastructure as Code practices and serves as a learning platform for DevOps methodologies in higher education.*