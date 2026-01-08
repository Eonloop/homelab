locals {   
  grackle = "booby"
  thrush = "eagle"
  warbler = "warbler"
  
  template_name = "Debian-13-Cloud-Template"
  template_id = try([
    for vm in data.proxmox_virtual_environment_vms.template.vms : vm.vm_id
    if vm.name == local.template_name
  ][0], null)

  standard_disk = {
    datastore_id = var.datastore
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 150
  }

  standard_network = {
    bridge = "vmbr0"
    model  = "virtio"
  }

  standard_agent = {
    enabled = true
    type    = "virtio"
  }
}