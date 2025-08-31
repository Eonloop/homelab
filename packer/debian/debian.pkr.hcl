packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

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
variable "ssh_password" {
  type      = string
  sensitive = true
}
variable "user_ssh_password" {
  type = string
  sensitive = true
}
variable "ssh_public_key" {
  type = string
  sensitive = true
}

source "proxmox-iso" "debian-server" {

  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = "pve"
  insecure_skip_tls_verify = true

  vm_id                = 9001
  template_name        = "debian-13-cloud-template"
  template_description = "Debian 13 Cloud Template, built on ${timestamp()}"
  boot_iso {
    type         = "scsi"
    iso_file     = "local:iso/debian-13.0.0-amd64-netinst.iso"
    unmount      = true
    iso_checksum = "sha512:069d47e9013cb1d651d30540fe8ef6765e5d60c8a14c8854dfb82e50bbb171255d2e02517024a392e46255dcdd18774f5cbd7e9f3a47aa1b489189475de62675"
  }

  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg", {
      root_password = var.ssh_password
      user_password = var.user_ssh_password
    })
  }
  boot_wait      = "5s"
  boot_command = [
    "<esc><wait>",
    "install ",
    "auto=true ",
    "priority=critical ",
    "DEBIAN_FRONTEND=text ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "<enter>"
  ]


  ssh_username = "eonloop"
  ssh_password = var.user_ssh_password
  ssh_timeout  = "30m"
  ssh_handshake_attempts = 30

  scsi_controller = "virtio-scsi-pci"

  efi_config {
    efi_storage_pool = "local-lvm"
    efi_type         = "4m"
  }

  disks {
    type         = "scsi"
    disk_size    = "32G"
    storage_pool = "local-lvm"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  memory = 4096
  cores  = 2
}

build {
  sources = ["source.proxmox-iso.debian-server"]

# Provisioner to add the SSH public key
  provisioner "shell" {
    inline = [
      "echo 'Installing public SSH key...'",
      "mkdir -p /home/eonloop/.ssh",
      "echo '${var.ssh_public_key}' > /home/eonloop/.ssh/authorized_keys",
      "chown -R eonloop:eonloop /home/eonloop/.ssh",
      "chmod 700 /home/eonloop/.ssh",
      "chmod 600 /home/eonloop/.ssh/authorized_keys"
    ]
  }

# Provisioner to prepare for templating
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to finish...'",
      "cloud-init status --wait",
      "echo 'Cleaning up the system for templating...'",
      "sudo apt-get clean",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "echo 'Build completed!'"
    ]
  }

  # Provisioner to update package lists and install base tools on debian
  provisioner "shell" {
    inline = [
      "echo 'Updating package lists and installing tools...'",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "echo 'Installing curl and wget...'",
      "sudo apt-get install -y curl wget"
    ]
  }
}
