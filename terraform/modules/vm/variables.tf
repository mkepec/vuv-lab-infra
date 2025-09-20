# VM Module Variables - Production-Ready Proxmox VM Configuration
# Single Subnet Approach

# VM Identity
variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_description" {
  description = "Description of the VM"
  type        = string
  default     = "Terraform managed VM"
}

# Proxmox Configuration
variable "target_node" {
  description = "Proxmox node where VM will be created"
  type        = string
}

variable "template_name" {
  description = "VM template to clone from"
  type        = string
}

# Resource Allocation
variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "cpu_sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "disk_storage" {
  description = "Storage pool for disk"
  type        = string
  default     = "local-lvm"
}

# Network Configuration - Single Subnet
variable "network_bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IP address in CIDR notation (e.g., 192.168.1.100/24). Leave empty for DHCP."
  type        = string
  default     = ""
}

variable "gateway" {
  description = "Network gateway (required for static IP)"
  type        = string
  default     = ""
}

variable "use_dhcp" {
  description = "Use DHCP for IP assignment instead of static IP"
  type        = bool
  default     = true
}

# Cloud-init Configuration
variable "ci_user" {
  description = "Cloud-init user"
  type        = string
  default     = "ubuntu"
}

variable "ci_password" {
  description = "Cloud-init password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "SSH public keys for user authentication"
  type        = string
}

# Advanced Options
variable "enable_agent" {
  description = "Enable QEMU guest agent"
  type        = bool
  default     = false
}

variable "enable_serial_console" {
  description = "Enable serial console for debugging"
  type        = bool
  default     = true
}