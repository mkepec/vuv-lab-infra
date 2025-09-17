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

variable "lxc_template" {
  description = "LXC container template"
  type        = string
  default     = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

variable "ssh_public_key" {
  description = "SSH public key for LXC access (paste your ~/.ssh/proxmox_key.pub content here)"
  type        = string
}

variable "network_gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.1.1"
}