variable "proxmox_host" {
  description = "Proxmox VE hostname or IP address"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox VE node name"
  type        = string
}

variable "template_name" {
  description = "VM template name to clone from"
  type        = string
  default     = "ubuntu2404-cloud"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (paste your ~/.ssh/proxmox_key.pub content here)"
  type        = string
}

variable "vm_password" {
  description = "Password for VM user (for testing - use SSH keys in production)"
  type        = string
  default     = "password123"
  sensitive   = true
}

# LXC container configuration
variable "lxc_count" {
  description = "Number of utility LXC containers to create"
  type        = number
  default     = 3
}

variable "lxc_template" {
  description = "LXC container template"
  type        = string
  default     = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

variable "network_base" {
  description = "Base network for IPs (e.g., 192.168.1)"
  type        = string
  default     = "192.168.1"
}

variable "network_gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.1.1"
}