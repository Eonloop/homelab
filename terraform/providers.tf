terraform {
  cloud { 
    
    organization = "eonloop" 

    workspaces { 
      name = "proxmox-homelab" 
    } 
  } 

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.78.0"
    }
    
  }
}

provider "proxmox" {
 endpoint  = "https://192.168.1.15:8006/api2/json"
 api_token      = var.proxmox_api_token
 insecure = true

 ssh {
  agent  = true
  username = "root"
  password = var.proxmox_ssh_password
 }
}