#!/bin/bash
# LXC Template Setup Script for VUV Lab Infrastructure
# This script downloads essential LXC templates for Terraform deployment

set -e  # Exit on any error

echo "=========================================="
echo "VUV Lab Infrastructure - LXC Template Setup"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root"
    echo "Usage: sudo $0"
    exit 1
fi

# Check available disk space
AVAILABLE_SPACE=$(df /var/lib/vz/ | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_SPACE" -lt 2097152 ]; then  # 2GB in KB
    echo "Warning: Less than 2GB available space in /var/lib/vz/"
    echo "Consider freeing up space before downloading templates"
fi

echo "Step 1: Updating template repository..."
pveam update
echo "✓ Template repository updated"

echo ""
echo "Step 2: Checking available Ubuntu templates..."
AVAILABLE_TEMPLATES=$(pveam available | grep ubuntu-24.04-standard || true)
if [ -z "$AVAILABLE_TEMPLATES" ]; then
    echo "Warning: No Ubuntu 24.04 templates found"
    echo "Available Ubuntu templates:"
    pveam available | grep ubuntu | head -5
    exit 1
fi

echo "Available Ubuntu 24.04 templates:"
echo "$AVAILABLE_TEMPLATES"

echo ""
echo "Step 3: Downloading Ubuntu 24.04 LTS template..."
UBUNTU_24_TEMPLATE=$(echo "$AVAILABLE_TEMPLATES" | head -1 | awk '{print $2}')
echo "Downloading: $UBUNTU_24_TEMPLATE"

# Check if template already exists
if pveam list local | grep -q "$UBUNTU_24_TEMPLATE"; then
    echo "✓ Template $UBUNTU_24_TEMPLATE already exists"
else
    echo "Downloading template (this may take several minutes)..."
    pveam download local "$UBUNTU_24_TEMPLATE"
    echo "✓ Template downloaded successfully"
fi

echo ""
echo "Step 4: Downloading Ubuntu 22.04 LTS template (fallback)..."
UBUNTU_22_AVAILABLE=$(pveam available | grep ubuntu-22.04-standard | head -1 || true)
if [ ! -z "$UBUNTU_22_AVAILABLE" ]; then
    UBUNTU_22_TEMPLATE=$(echo "$UBUNTU_22_AVAILABLE" | awk '{print $2}')
    if pveam list local | grep -q "$UBUNTU_22_TEMPLATE"; then
        echo "✓ Template $UBUNTU_22_TEMPLATE already exists"
    else
        echo "Downloading: $UBUNTU_22_TEMPLATE"
        pveam download local "$UBUNTU_22_TEMPLATE"
        echo "✓ Fallback template downloaded"
    fi
else
    echo "No Ubuntu 22.04 templates available"
fi

echo ""
echo "Step 5: Verifying template installation..."
echo "Downloaded Ubuntu templates:"
pveam list local | grep ubuntu

echo ""
echo "Step 6: Checking storage usage..."
echo "Storage usage for /var/lib/vz/:"
df -h /var/lib/vz/

echo ""
echo "=========================================="
echo "✓ LXC Template setup completed successfully!"
echo "=========================================="

echo ""
echo "Next steps:"
echo "1. Update your Terraform configuration with the exact template name:"
echo "   Primary template: $UBUNTU_24_TEMPLATE"
if [ ! -z "$UBUNTU_22_TEMPLATE" ]; then
echo "   Fallback template: $UBUNTU_22_TEMPLATE"
fi

echo ""
echo "2. Update terraform.tfvars with:"
echo "   lxc_template = \"$UBUNTU_24_TEMPLATE\""

echo ""
echo "3. Test Terraform LXC deployment:"
echo "   cd terraform/test"
echo "   terraform plan"
echo "   terraform apply"

echo ""
echo "Template files location: /var/lib/vz/template/cache/"
echo "Template verification: pveam list local | grep ubuntu"