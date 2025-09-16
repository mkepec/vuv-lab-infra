variable "proxmox_host" {
  description = "Proxmox VE hostname or IP"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox VE username"
  type        = string
  default     = "terraform@pve"
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox VE node name"
  type        = string
}

variable "template_name" {
  description = "VM template name"
  type        = string
  default     = "ubuntu2404-cloud"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

# Network configuration
variable "network_base" {
  description = "Base network for VMs (e.g., 192.168.1)"
  type        = string
  default     = "192.168.1"
}

variable "network_gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.1.1"
}

# GNS3 Server configuration
variable "gns3_server_count" {
  description = "Number of GNS3 servers to create"
  type        = number
  default     = 1
}

variable "gns3_server_memory" {
  description = "Memory allocation for GNS3 servers (MB)"
  type        = number
  default     = 4096
}

variable "gns3_server_cores" {
  description = "CPU cores for GNS3 servers"
  type        = number
  default     = 4
}

# Docker host configuration
variable "docker_host_count" {
  description = "Number of Docker hosts to create"
  type        = number
  default     = 2
}

variable "docker_host_memory" {
  description = "Memory allocation for Docker hosts (MB)"
  type        = number
  default     = 2048
}

variable "docker_host_cores" {
  description = "CPU cores for Docker hosts"
  type        = number
  default     = 2
}

# LXC container configuration
variable "lxc_template" {
  description = "LXC container template"
  type        = string
  default     = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

variable "utility_lxc_count" {
  description = "Number of utility LXC containers to create"
  type        = number
  default     = 3
}