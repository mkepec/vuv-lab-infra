# Testing Guide - Ansible Setup Validation

This guide provides step-by-step testing procedures for validating the Ansible setup using a test Ubuntu VM.

## Test Scenario

**Testing Environment:**
- **Test VM**: Ubuntu VM with user `ubuntu` and password `test123`
- **VM IP**: `192.168.1.38`
- **SSH Key**: `~/.ssh/vuv-lab-key` (generated for testing)
- **Goal**: Validate Ansible bootstrap process and documentation

## Prerequisites Verification

Before starting, verify your testing environment:

### 1. Test VM Accessibility

```bash
# Test SSH connection with password (should work)
ssh ubuntu@192.168.1.38

# You should be prompted for password: test123
# Once logged in, verify sudo access:
sudo whoami  # Should return: root

# Exit the VM
exit
```

### 2. SSH Key Verification

```bash
# Check that your SSH key exists
ls -la ~/.ssh/vuv-lab-key*

# Should show both:
# ~/.ssh/vuv-lab-key (private key)
# ~/.ssh/vuv-lab-key.pub (public key)

# Display public key content (you'll need this for reference)
cat ~/.ssh/vuv-lab-key.pub
```

### 3. Ansible Installation Check

```bash
# Verify Ansible is installed
ansible --version

# Should show version 2.15+ 
# If not installed, follow the installation guide:
sudo apt update && sudo apt install ansible -y
```

## Step-by-Step Testing Procedure

### Step 1: Navigate to Ansible Directory

```bash
# Navigate to the project ansible directory
cd /path/to/vuv-lab-infra/ansible

# Verify directory structure
ls -la
# Should show: ansible.cfg, inventory/, playbooks/, ssh_keys/
```

### Step 2: Verify Configuration

```bash
# Check ansible configuration
cat ansible.cfg

# Key settings to verify:
# - remote_user = lab
# - private_key_file = ~/.ssh/vuv-lab-key
# - inventory = ./inventory/hosts

# Check inventory configuration
cat inventory/hosts

# Verify test VM is listed:
# [test]
# test-ubuntu ansible_host=192.168.1.38
```

### Step 3: Test Initial Connectivity (Should Fail)

```bash
# This should fail because 'lab' user doesn't exist yet
ansible test -m ping

# Expected result: UNREACHABLE or FAILED
# This is normal - the lab user hasn't been created yet
```

### Step 4: Run Bootstrap Playbook

```bash
# Run bootstrap with password authentication
ansible-playbook -k playbooks/bootstrap.yml --limit test

# When prompted for SSH password, enter: test123
# The playbook will:
# 1. Connect as 'ubuntu' user with password
# 2. Create 'lab' user
# 3. Deploy your SSH key to 'lab' user
# 4. Configure passwordless sudo
```

**Expected Output:**
```
PLAY [Bootstrap Lab VMs - Create lab user and configure access] ****

TASK [Gathering Facts] *************************************************
ok: [test-ubuntu]

TASK [Create lab group] ************************************************
changed: [test-ubuntu]

TASK [Create lab user] *************************************************
changed: [test-ubuntu]

TASK [Configure passwordless sudo for lab user] ***********************
changed: [test-ubuntu]

[... more tasks ...]

PLAY RECAP *************************************************************
test-ubuntu               : ok=10   changed=8    unreachable=0    failed=0
```

### Step 5: Verify Bootstrap Success

```bash
# Test connectivity as lab user (should now work)
ansible test -m ping

# Expected output:
# test-ubuntu | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }

# Test sudo access
ansible test -m shell -a "whoami" --become

# Expected output:
# test-ubuntu | CHANGED | rc=0 >>
# root
```

### Step 6: Test SSH Key Access

```bash
# Test direct SSH connection as lab user
ssh -i ~/.ssh/vuv-lab-key lab@192.168.1.38

# Should connect without password prompt
# Once connected, test sudo:
sudo whoami  # Should return: root

# Exit
exit
```

### Step 7: Run Post-Bootstrap Playbooks

```bash
# Run initial setup playbook
ansible-playbook playbooks/initial_setup.yml --limit test

# Run system updates
ansible-playbook playbooks/system_updates.yml --limit test

# Run security hardening
ansible-playbook playbooks/security_hardening.yml --limit test
```

## Validation Checklist

Mark each item as you complete testing:

### Bootstrap Process
- [ ] `ansible test -m ping` initially fails (expected)
- [ ] Bootstrap playbook runs without errors
- [ ] Bootstrap creates `lab` user successfully
- [ ] SSH key is deployed correctly
- [ ] Passwordless sudo is configured

### Post-Bootstrap Connectivity
- [ ] `ansible test -m ping` returns SUCCESS
- [ ] `ansible test -m shell -a "whoami" --become` returns "root"
- [ ] Direct SSH as lab user works: `ssh -i ~/.ssh/vuv-lab-key lab@192.168.1.38`
- [ ] Sudo access works without password prompt

### Configuration Playbooks
- [ ] Initial setup playbook completes successfully
- [ ] System updates playbook completes successfully  
- [ ] Security hardening playbook completes successfully
- [ ] UFW firewall is active and configured
- [ ] SSH password authentication is disabled

### Documentation Testing
- [ ] Getting Started guide flow is clear
- [ ] Ansible setup guide is easy to follow
- [ ] Troubleshooting section addresses common issues
- [ ] SSH key setup instructions are accurate

## Common Issues and Solutions

### Issue: "Permission denied (publickey)"

**Cause**: SSH key not properly deployed or wrong key path

**Solution**:
```bash
# Verify key path in configuration
grep private_key_file ansible.cfg

# Check if key exists
ls -la ~/.ssh/vuv-lab-key*

# Re-run bootstrap if needed
ansible-playbook -k playbooks/bootstrap.yml --limit test
```

### Issue: "Could not match supplied host pattern"

**Cause**: Inventory not properly configured

**Solution**:
```bash
# Check inventory syntax
ansible-inventory --graph

# Verify test group exists
ansible test --list-hosts
```

### Issue: Bootstrap playbook fails on user creation

**Cause**: Incorrect initial user or permissions

**Solution**:
```bash
# Test initial connectivity manually
ssh ubuntu@192.168.1.38

# Check if user has sudo access
sudo whoami

# Verify ansible is connecting with correct user
ansible-playbook -k playbooks/bootstrap.yml --limit test -vvv
```

### Issue: "Host key verification failed"

**Cause**: SSH host key not in known_hosts

**Solution**:
```bash
# Remove old host key
ssh-keygen -R 192.168.1.38

# Or add host key
ssh-keyscan 192.168.1.38 >> ~/.ssh/known_hosts
```

## Feedback Collection

After completing the testing, please provide feedback on:

### Documentation Quality
- [ ] **Clear progression** from Terraform to Ansible
- [ ] **Easy to follow** step-by-step instructions
- [ ] **Comprehensive troubleshooting** coverage
- [ ] **Accurate command examples** and expected outputs

### Bootstrap Process
- [ ] **Playbook execution** smooth and error-free
- [ ] **SSH key deployment** works as expected
- [ ] **User creation** and sudo configuration successful
- [ ] **Error messages** are helpful and actionable

### Configuration Management
- [ ] **Post-bootstrap playbooks** run successfully
- [ ] **System configuration** applied correctly
- [ ] **Security settings** implemented properly
- [ ] **Team collaboration** features work as designed

### Areas for Improvement
- **Documentation gaps**: What was unclear or missing?
- **Error scenarios**: What unexpected issues occurred?
- **User experience**: What could be simplified or automated?
- **Missing features**: What additional functionality is needed?

## Test Results Template

```
# Ansible Setup Testing Results

**Date**: [DATE]
**Tester**: [NAME]
**Environment**: Ubuntu VM (192.168.1.38)

## Test Results

### Bootstrap Process: [PASS/FAIL]
- Bootstrap playbook execution: [PASS/FAIL]
- Lab user creation: [PASS/FAIL]  
- SSH key deployment: [PASS/FAIL]
- Sudo configuration: [PASS/FAIL]

### Post-Bootstrap Testing: [PASS/FAIL]
- Ansible connectivity: [PASS/FAIL]
- Initial setup playbook: [PASS/FAIL]
- System updates playbook: [PASS/FAIL]
- Security hardening playbook: [PASS/FAIL]

### Documentation Quality: [RATING 1-5]
- Getting Started flow: [RATING]
- Ansible setup guide: [RATING]
- Troubleshooting coverage: [RATING]
- Overall clarity: [RATING]

## Issues Encountered
[Describe any problems, error messages, or confusion]

## Suggestions for Improvement
[Recommendations for documentation or process improvements]

## Additional Notes
[Any other observations or feedback]
```

This testing validates that university IT staff can successfully follow the documentation and deploy the Ansible configuration management system.