#cloud-config

# SSH Configuration for reliable connectivity
ssh_pwauth: false
disable_root: true

# Create user with sudo privileges
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${ssh_public_key}

# Ensure SSH service is enabled and started
runcmd:
  # Enable and start SSH service
  - systemctl enable ssh
  - systemctl start ssh
  
  # Configure SSH daemon for reliable access
  - |
    cat >> /etc/ssh/sshd_config << 'EOF'
    
    # Enhanced SSH configuration for lab environment
    PermitRootLogin no
    PubkeyAuthentication yes
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    UsePAM yes
    X11Forwarding yes
    PrintMotd no
    AcceptEnv LANG LC_*
    Subsystem sftp /usr/lib/openssh/sftp-server
    
    # Allow ubuntu user specifically
    AllowUsers ubuntu
    
    # Network timeout settings
    ClientAliveInterval 60
    ClientAliveCountMax 3
    TCPKeepAlive yes
    EOF
  
  # Restart SSH service to apply configuration
  - systemctl restart ssh
  
  # Disable UFW firewall (or configure it properly)
  - ufw --force disable
  
  # Alternative: Configure UFW to allow SSH
  # - ufw allow ssh
  # - ufw --force enable
  
  # Ensure proper permissions on SSH directory
  - chmod 700 /home/ubuntu/.ssh
  - chmod 600 /home/ubuntu/.ssh/authorized_keys
  - chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Package updates and installations
package_update: true
package_upgrade: false

# Install essential packages
packages:
  - openssh-server
  - curl
  - wget
  - net-tools
  - htop

# Write additional files if needed
write_files:
  - path: /etc/ssh/ssh_banner
    content: |
      ===============================================
      VUV Lab Infrastructure - Test VM
      Authorized access only
      ===============================================
    permissions: '0644'
    owner: root:root

# Final commands to ensure everything is working
final_message: |
  Cloud-init setup complete!
  SSH should now be accessible on port 22
  Connect with: ssh ubuntu@<vm_ip>