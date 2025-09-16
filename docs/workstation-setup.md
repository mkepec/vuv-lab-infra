# Workstation Setup for VUV Lab Infrastructure

This guide provides detailed instructions for setting up your local workstation to work with the VUV lab infrastructure. It covers tool installation, SSH key management, and troubleshooting for different operating systems.

## Prerequisites

- Completed [Proxmox Setup](proxmox-setup.md) with working API token
- Administrative access to your local workstation
- Internet connectivity for downloading tools

## Overview

You'll install and configure:
- **Terraform** - Infrastructure provisioning tool
- **Git** - Version control system (optional for basic lab setup)
- **SSH Client** - Secure access to VMs
- **Text Editor** - For configuration file editing
- **SSH Keys** - Secure authentication to deployed VMs

## Windows Setup

### Method 1: Chocolatey (Recommended)

Chocolatey is a package manager that simplifies Windows software installation:

#### Install Chocolatey

```powershell
# Open PowerShell as Administrator (Right-click -> Run as Administrator)

# Check execution policy
Get-ExecutionPolicy

# If Restricted, allow script execution temporarily
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Verify installation
choco --version
```

#### Install Required Tools

```powershell
# Install all required tools
choco install terraform git openssh vscode -y

# Verify installations
terraform version
git --version
ssh -V
```

### Method 2: Manual Installation

If you can't use Chocolatey (corporate restrictions, etc.):

#### Terraform

1. Visit https://developer.hashicorp.com/terraform/downloads
2. Download Windows AMD64 version
3. Extract `terraform.exe` to `C:\Tools\terraform\`
4. Add `C:\Tools\terraform\` to your PATH environment variable
5. Verify: Open new Command Prompt and run `terraform version`

#### Git

1. Visit https://git-scm.com/download/win
2. Download and run the installer
3. Use default settings (including "Git from the command line and also from 3rd-party software")
4. Verify: `git --version`

#### OpenSSH

```powershell
# OpenSSH is built into Windows 10/11
# Enable if not already available
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Verify
ssh -V
```

### Windows-Specific Configuration

#### PATH Environment Variable

If tools aren't recognized, add them to PATH:

```powershell
# Check current PATH
$env:PATH -split ';'

# Add terraform (if manual installation)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Tools\terraform", [EnvironmentVariableTarget]::User)

# Restart PowerShell to reload PATH
```

#### PowerShell Execution Policy

```powershell
# If you encounter execution policy errors
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Linux Setup

### Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install required packages
sudo apt install -y curl wget unzip git openssh-client

# Install Terraform (official HashiCorp repository)
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installations
terraform version
git --version
ssh -V
```

### CentOS/RHEL/Rocky Linux

```bash
# Install EPEL repository
sudo dnf install -y epel-release

# Install basic tools
sudo dnf install -y curl wget unzip git openssh-clients

# Install Terraform
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install terraform

# Verify installations
terraform version
git --version
ssh -V
```

### Arch Linux

```bash
# Install required packages
sudo pacman -S terraform git openssh

# Verify installations
terraform version
git --version
ssh -V
```

## macOS Setup

### Method 1: Homebrew (Recommended)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install terraform git openssh

# Verify installations
terraform version
git --version
ssh -V
```

### Method 2: Manual Installation

Similar to Windows manual installation, but download macOS versions of each tool.

## SSH Key Generation

### Generate SSH Key Pair

```bash
# Generate ED25519 key (recommended for security and performance)
ssh-keygen -t ed25519 -C "vuv-lab-proxmox" -f ~/.ssh/proxmox_key

# If ED25519 is not supported (older systems)
ssh-keygen -t rsa -b 4096 -C "vuv-lab-proxmox" -f ~/.ssh/proxmox_key
```

**Key Generation Options:**
- `-t ed25519`: Use ED25519 algorithm (most secure and fast)
- `-C "vuv-lab-proxmox"`: Comment to identify the key
- `-f ~/.ssh/proxmox_key`: Save to specific filename

### Secure Key Permissions

```bash
# Set proper permissions (Unix/Linux/macOS)
chmod 600 ~/.ssh/proxmox_key      # Private key: read/write for owner only
chmod 644 ~/.ssh/proxmox_key.pub  # Public key: readable by others

# On Windows (PowerShell)
icacls $env:USERPROFILE\.ssh\proxmox_key /inheritance:r /grant:r "$env:USERNAME:R"
```

### Display Public Key

```bash
# Display public key (you'll need this for Terraform configuration)
cat ~/.ssh/proxmox_key.pub

# On Windows
type %USERPROFILE%\.ssh\proxmox_key.pub
```

**Save this public key!** You'll paste it into your `terraform.tfvars` file.

## Verification and Testing

### Tool Verification

```bash
# Check Terraform version (should be 1.5+)
terraform version

# Check Git configuration
git --version
git config --global --list

# Test SSH key (Linux/macOS)
ssh-keygen -l -f ~/.ssh/proxmox_key.pub

# Test SSH key (Windows)
ssh-keygen -l -f "%USERPROFILE%\.ssh\proxmox_key.pub"
```

### Initial Git Configuration (Optional)

**Note**: Git configuration is optional for this lab setup. If you plan to use version control or clone this repository from GitHub, configure Git as follows:

```bash
# Set up Git identity (replace with your information)
git config --global user.name "Your Name"
git config --global user.email "your-email@university.edu"

# Verify configuration (will create config file if it doesn't exist)
git config --global user.name
git config --global user.email

# Alternative: View all global Git settings
git config --global --list
```

**If you encounter "unable to read config file" error**: This is normal for a fresh Git installation. The global config file will be created when you set your first configuration option.

## Corporate/University Network Considerations

### Firewall Considerations

Ensure these ports are accessible:
- **8006/tcp** - Proxmox web interface and API
- **22/tcp** - SSH to deployed VMs
- **443/tcp** - HTTPS for package downloads

## Text Editor Setup

### Visual Studio Code (Recommended)

#### Install Extensions via Command Line

Run these commands from your terminal/command prompt (after VS Code is installed):

```bash
# Install VS Code extensions for better editing
code --install-extension HashiCorp.terraform
code --install-extension ms-vscode.powershell
code --install-extension redhat.ansible
```

#### Install Extensions via VS Code GUI

Alternatively, install extensions through VS Code interface:

1. Open Visual Studio Code
2. Click the Extensions icon in the sidebar (or press `Ctrl+Shift+X`)
3. Search for and install these extensions:
   - **HashiCorp Terraform** - Syntax highlighting and validation for Terraform files
   - **PowerShell** - PowerShell language support (Windows)
   - **Ansible** - YAML and Ansible playbook support

### Alternative Editors

- **Windows**: Notepad++, Sublime Text
- **Linux/macOS**: vim, nano, emacs, Sublime Text

## Troubleshooting

### Common Issues

#### Terraform Command Not Found

**Windows:**
```powershell
# Check if terraform is in PATH
where terraform

# If not found, add to PATH manually or reinstall
```

**Linux/macOS:**
```bash
# Check if terraform is in PATH
which terraform

# Add to PATH if needed
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

#### SSH Key Permission Errors

```bash
# Linux/macOS: Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/proxmox_key
chmod 644 ~/.ssh/proxmox_key.pub

# Windows: Use icacls to set proper permissions
icacls %USERPROFILE%\.ssh /inheritance:r /grant:r "%USERNAME%:F"
```

#### Git SSL Certificate Issues

```bash
# Temporary workaround (not recommended for production)
git config --global http.sslVerify false

# Better solution: Install proper certificates or configure proxy
```

#### Chocolatey Installation Fails

```powershell
# Common issues and solutions:

# 1. Execution Policy
Set-ExecutionPolicy Bypass -Scope Process -Force

# 2. TLS Issues
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 3. Antivirus blocking
# Temporarily disable real-time protection during installation
```

#### Package Installation Fails

**Ubuntu/Debian:**
```bash
# If apt repositories are out of date
sudo apt update --fix-missing

# If dpkg is locked
sudo dpkg --configure -a
```

**macOS:**
```bash
# If Homebrew has issues
brew doctor
brew update
```

### Corporate Environment Issues

#### Package Manager Restrictions

If you can't use package managers:
1. Download tools manually from official websites
2. Use portable versions when available
3. Request IT department to install required tools
4. Consider using Windows Subsystem for Linux (WSL)

#### Network Restrictions

1. **Work with IT**: Request firewall exceptions for required ports
2. **VPN Access**: Ensure VPN allows access to Proxmox server
3. **DNS Issues**: Use IP addresses if DNS resolution fails

## Validation Checklist

Before proceeding to Terraform configuration:

### Tool Installation
- [ ] Terraform installed and accessible (`terraform version` works)
- [ ] Git installed and configured
- [ ] SSH client available and working
- [ ] Text editor installed and configured

### SSH Configuration
- [ ] SSH key pair generated (`~/.ssh/proxmox_key` and `~/.ssh/proxmox_key.pub` exist)
- [ ] Proper file permissions set on SSH keys
- [ ] Public key content saved/copied for later use
- [ ] SSH key format verified (`ssh-keygen -l -f ~/.ssh/proxmox_key.pub` works)

### Network and Access
- [ ] Can access Proxmox web interface from workstation
- [ ] No blocking firewall rules or proxy issues
- [ ] Git can clone repositories (optional - test with `git clone https://github.com/hashicorp/terraform.git /tmp/test-repo`)
- [ ] Internet access for Terraform provider downloads

### Git Configuration (Optional)
- [ ] Git user name and email configured (only if using version control)
- [ ] Can clone this repository from GitHub if desired
- [ ] SSH or HTTPS access to your project repository

## Performance Optimization

### Terraform Performance

```bash
# Enable Terraform logging for debugging
export TF_LOG=INFO

# Use faster DNS servers if experiencing slowness
# Add to /etc/resolv.conf (Linux) or network settings
nameserver 8.8.8.8
nameserver 1.1.1.1
```

### SSH Performance

```bash
# Add to ~/.ssh/config for faster connections
Host *
    ControlMaster auto
    ControlPath ~/.ssh/control_%h_%p_%r
    ControlPersist 10m
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

## Next Steps

✅ **Workstation is now ready for infrastructure work!**

### Continue with the Setup Process

1. **Return to Getting Started**: Go back to [Getting Started Guide](getting-started.md#step-3-terraform-configuration) to continue with Step 3: Terraform Configuration
2. **Next Detailed Guide**: Proceed to [Terraform Configuration Guide](terraform-configuration.md) for complete infrastructure setup

### What You've Accomplished

- ✅ All required tools installed and working
- ✅ SSH key pair generated for secure VM access
- ✅ Network connectivity verified
- ✅ Development environment ready

### Guide Navigation

- ⬅️ **Previous**: [Proxmox Setup Guide](proxmox-setup.md) (Proxmox VE configuration)
- ➡️ **Next**: [Terraform Configuration Guide](terraform-configuration.md) (detailed infrastructure setup)
- 📋 **Alternative**: Continue with [Getting Started Step 3](getting-started.md#step-3-terraform-configuration) (basic steps)

---

## Additional Resources

- **Terraform Documentation**: https://developer.hashicorp.com/terraform/docs
- **Git Documentation**: https://git-scm.com/doc
- **SSH Key Management**: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- **VS Code Extensions**: https://marketplace.visualstudio.com/vscode