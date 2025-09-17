# LXC Module Variables - Production-Ready Proxmox LXC Configuration
# Single Subnet Approach

# Container Identity
variable "container_name" {
  description = "Name/hostname of the LXC container"
  type        = string
}

variable "description" {
  description = "Description of the LXC container"
  type        = string
  default     = "Terraform managed LXC container"
}

# Proxmox Configuration
variable "target_node" {
  description = "Proxmox node where container will be created"
  type        = string
}

variable "template_name" {
  description = "LXC template to use (e.g., ubuntu-24.04-standard_24.04-2_amd64.tar.zst)"
  type        = string
}

# Resource Allocation
variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 512
}

variable "swap" {
  description = "Swap memory in MB"
  type        = number
  default     = 512
}

variable "disk_size" {
  description = "Root filesystem size (e.g., '8G')"
  type        = string
  default     = "8G"
}

variable "disk_storage" {
  description = "Storage pool for container filesystem"
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
  description = "Static IP address in CIDR notation (e.g., 192.168.1.160/24)"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

# Container Features
variable "enable_nesting" {
  description = "Allow nested virtualization (Docker, etc.)"
  type        = bool
  default     = true
}

variable "privileged" {
  description = "Run as privileged container (less secure)"
  type        = bool
  default     = false
}

# SSH Configuration
variable "ssh_public_keys" {
  description = "SSH public keys for root authentication"
  type        = string
}

# Startup Configuration
variable "start_on_create" {
  description = "Start container immediately after creation"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Start container on Proxmox boot"
  type        = bool
  default     = true
}

# Organization
variable "tags" {
  description = "Tags for container organization (comma-separated)"
  type        = string
  default     = "terraform,lxc"
}