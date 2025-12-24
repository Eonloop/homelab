variable "proxmox_api_token" {
  description = "API token for BGP Proxmox Provider"
  type        = string
  sensitive   = true
}

variable "proxmox_ssh_password" {
  description = "Password for the SSH user (root) on the Proxmox host."
  type        = string
  sensitive   = true
}

variable "vm_user_password" {
  description = "Password for the user account inside the VMs."
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Local path to SSH public key to install on VMs"
  type        = string
  sensitive   = true
}

variable "datastore" {
  description = "Name of the storage medium"
  type        = string
  sensitive   = true
}