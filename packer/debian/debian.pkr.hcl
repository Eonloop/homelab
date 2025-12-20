packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "debian-server" {

  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true
  qemu_agent = true

  vm_id                = var.vm_id
  template_name        = "Debian-13-Cloud-Template"
  template_description = "Debian 13 Cloud Template, built on ${timestamp()}"
  boot_iso {
    type         = "scsi"
    iso_file     = "local:iso/debian-13.2.0-amd64-netinst.iso"
    unmount      = true
    iso_checksum = "none"
  }

  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg", {
      root_password = var.ssh_password
      user_password = var.user_ssh_password
    })
  }
  boot_wait      = "10s"
  boot_command = [
    "<esc><wait>",
    "install ",
    "auto=true ",
    "priority=critical ",
    "DEBIAN_FRONTEND=text ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "<enter>"
  ]

  # Wait for installation to complete and system to reboot
  # The guest agent will only be available after the first boot
  communicator = "ssh"
  ssh_username = var.ssh_username
  ssh_password = var.user_ssh_password
  ssh_timeout  = "30m"
  ssh_handshake_attempts = 30
  # Don't try to connect until after installation completes
  # Packer will wait for SSH to become available

  scsi_controller = "virtio-scsi-pci"

  disks {
    type         = "scsi"
    disk_size    = "32G"
    storage_pool = var.storage_pool
  }

  network_adapters {
    model  = "virtio"
    bridge = var.network_bridge
  }

  memory = 4096
  cores  = 2
}

build {
  sources = ["source.proxmox-iso.debian-server"]

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent cloud-init",
      "sudo systemctl enable qemu-guest-agent",
    ]
  }

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "export DEBIAN_FRONTEND=noninteractive",

      "echo 'Waiting for apt locks...'",
      "while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 2; done",

      "echo 'Updating system packages...'",
      "sudo apt-get -yq update",
      "sudo apt-get -yq -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold dist-upgrade",
      "sudo apt-get -yq purge apt-listchanges || true",

      "sudo apt-get -yq autoremove",
      "sudo apt-get -yq clean",
    ]
  }


  provisioner "shell" {
    inline = [
      "set -euxo pipefail",

      "echo 'Resetting cloud-init state for templating...'",
      "sudo cloud-init clean --logs --seed",

      "echo 'Removing SSH host keys...'",
      "sudo rm -f /etc/ssh/ssh_host_*",

      "echo 'Resetting machine-id...'",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm -f /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",

      "echo 'Clearing bash history...'",
      "unset HISTFILE",
      "sudo rm -f /root/.bash_history",
      "sudo rm -f /home/eonloop/.bash_history",

      "echo 'Build completed!'",
    ]
  }

}
