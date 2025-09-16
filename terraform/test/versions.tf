terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_host}:8006/api2/json"
  pm_api_token_id     = "terraform@pve!terraform-token"
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = true
}