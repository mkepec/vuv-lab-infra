# Legacy outputs removed - using modular approach instead
# All VM and LXC information now available through production module outputs below

# Production VMs Output - Using Module Outputs
output "production_vms" {
  description = "Production VMs information"
  value = {
    for vm_name, vm_module in module.production_vms :
    vm_name => vm_module.vm_info
  }
}

# SSH Commands for Production VMs
output "production_vm_ssh_commands" {
  description = "SSH commands for all production VMs"
  value = {
    for vm_name, vm_module in module.production_vms :
    vm_name => vm_module.ssh_command
  }
}

# Clean modular infrastructure summary
output "infrastructure_summary" {
  description = "Summary of modular infrastructure deployment"
  value = {
    environment      = "test"
    architecture     = "shared-modules"
    network_approach = "Single subnet (${var.network_base}.x/24)"
    production_vms   = length(local.production_vms)
    production_lxc   = length(local.production_lxc)
    vm_names         = keys(local.production_vms)
    lxc_names        = keys(local.production_lxc)
    total_resources  = length(local.production_vms) + length(local.production_lxc)
    modules_used     = ["../modules/vm", "../modules/lxc"]
  }
}

# Production LXC Output - Using Module Outputs
output "production_lxc" {
  description = "Production LXC containers information"
  value = {
    for container_name, container_module in module.production_lxc :
    container_name => container_module.container_info
  }
}

# SSH Commands for Production LXC
output "production_lxc_ssh_commands" {
  description = "SSH commands for all production LXC containers"
  value = {
    for container_name, container_module in module.production_lxc :
    container_name => container_module.ssh_command
  }
}

# Complete infrastructure overview with all details
output "deployment_overview" {
  description = "Complete overview of the modular deployment"
  value = {
    summary = {
      environment     = "test"
      total_vms       = length(local.production_vms)
      total_lxc       = length(local.production_lxc)
      total_resources = length(local.production_vms) + length(local.production_lxc)
    }
    vms = {
      for vm_name, vm_module in module.production_vms :
      vm_name => {
        ip_address = vm_module.vm_info.ip_address
        resources  = "${vm_module.vm_info.cpu_cores}C/${vm_module.vm_info.memory_mb}MB/${vm_module.vm_info.disk_size}GB"
      }
    }
    lxc = {
      for lxc_name, lxc_module in module.production_lxc :
      lxc_name => {
        ip_address = lxc_module.container_info.ip_address
        resources  = "${lxc_module.container_info.cores}C/${lxc_module.container_info.memory_mb}MB/${lxc_module.container_info.disk_size}"
      }
    }
  }
}