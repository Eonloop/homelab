variable "proxmox_api_url" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "vm_id" {
  type = string
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "user_ssh_password" {
  type      = string
  sensitive = true
}

variable "ssh_username" {
  type = string
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "storage_pool" {
  type      = string
  sensitive = true
}

variable "network_bridge" {
  type = string
}

