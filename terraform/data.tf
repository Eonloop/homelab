# Read SSH public key
data "local_file" "ssh_public_key" {
  filename = pathexpand(var.ssh_public_key_path)
}

# Find the Packer template
data "proxmox_virtual_environment_vms" "template" {
  node_name = "grackle"
}