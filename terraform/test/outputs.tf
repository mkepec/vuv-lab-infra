# Test environment outputs - using modular approach
# All VM and LXC information available through test module outputs below

# Test VMs Output - Using Module Outputs
output "test_vms" {
  description = "Test VMs information"
  value = {
    for vm_name, vm_module in module.test_vms :
    vm_name => vm_module.vm_info
  }
}

# SSH Commands for Test VMs
output "test_vm_ssh_commands" {
  description = "SSH commands for all test VMs"
  value = {
    for vm_name, vm_module in module.test_vms :
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
    test_vms         = length(local.test_vms)
    test_lxc         = length(local.test_lxc)
    vm_names         = keys(local.test_vms)
    lxc_names        = keys(local.test_lxc)
    total_resources  = length(local.test_vms) + length(local.test_lxc)
    modules_used     = ["../modules/vm", "../modules/lxc"]
  }
}

# Test LXC Output - Using Module Outputs
output "test_lxc" {
  description = "Test LXC containers information"
  value = {
    for container_name, container_module in module.test_lxc :
    container_name => container_module.container_info
  }
}

# SSH Commands for Test LXC
output "test_lxc_ssh_commands" {
  description = "SSH commands for all test LXC containers"
  value = {
    for container_name, container_module in module.test_lxc :
    container_name => container_module.ssh_command
  }
}

# Complete infrastructure overview with all details
output "deployment_overview" {
  description = "Complete overview of the modular deployment"
  value = {
    summary = {
      environment     = "test"
      total_vms       = length(local.test_vms)
      total_lxc       = length(local.test_lxc)
      total_resources = length(local.test_vms) + length(local.test_lxc)
    }
    vms = {
      for vm_name, vm_module in module.test_vms :
      vm_name => {
        ip_address = vm_module.vm_info.ip_address
        resources  = "${vm_module.vm_info.cpu_cores}C/${vm_module.vm_info.memory_mb}MB/${vm_module.vm_info.disk_size}GB"
      }
    }
    lxc = {
      for lxc_name, lxc_module in module.test_lxc :
      lxc_name => {
        ip_address = lxc_module.container_info.ip_address
        resources  = "${lxc_module.container_info.cores}C/${lxc_module.container_info.memory_mb}MB/${lxc_module.container_info.disk_size}"
      }
    }
  }
}