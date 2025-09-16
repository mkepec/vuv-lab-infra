# Proxmox Provider Configuration for VUV Lab Infrastructure
# This configuration sets up the Proxmox provider for managing VMs and containers

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_host}:8006/api2/json"
  pm_api_token_id     = "${var.proxmox_user}!terraform-token"
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = true
  
  # Connection settings
  pm_timeout = 600
}