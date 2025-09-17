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

variable "network_gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.1.1"
}