resource "proxmox_virtual_environment_vm" "owl" {
  name      = "Owl"
  vm_id     = 205              # Hard-code this to avoid the 106 collision!
  node_name = local.warbler    # Use a local variable
  
  clone {
    vm_id     = local.template_id
    node_name = local.grackle
  }

  cpu {
    cores = 2                  
    type  = "host"
  }

  memory {
    dedicated = 4096          
  }

  initialization {
    ip_config {
      ipv4 { 
        address = "192.168.1.24/24"
        gateway = "192.168.1.1"
      }
    }
    user_account {
      username = "owl"
      password = var.vm_user_password
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  disk {
    datastore_id = local.standard_disk.datastore_id
    interface    = local.standard_disk.interface
    iothread     = local.standard_disk.iothread
    discard      = local.standard_disk.discard
    size         = local.standard_disk.size
  }

  network_device {
    bridge = local.standard_network.bridge
    model  = local.standard_network.model
  }

  agent {
    enabled = local.standard_agent.enabled
    type    = local.standard_agent.type
  }

  bios          = "seabios"
  boot_order    = ["scsi0"]
  scsi_hardware = "virtio-scsi-single"
}
