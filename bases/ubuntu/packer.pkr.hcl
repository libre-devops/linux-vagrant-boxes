variable "vm_name" {
  type        = string
  description = "The name of the VM"
  default     = "packer-ubuntu22.04base"
}

variable "username" {
  type        = string
  description = "The username of the default user"
  default     = "vagrant"
}

variable "password" {
  type        = string
  description = "The password of the default user"
  default     = "vagrant"
}

variable "hashed_password" {
  type        = string
  description = "The hashed password of the default user. You will need to generate this with openssl or mkpasswd on NIX systems"
  default     = "vagrant"
}

variable "os_version" {
  type        = string
  description = "The version of OS to use"
  default     = "22.04.2"
}

variable "os_checksum" {
  type        = string
  description = "The checksum of the OS, can be fetched programmatically"
  default     = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
}

variable "os_type" {
  type        = string
  description = "The type of OS, e.g, server-amd64 etc"
  default     = "live-server-amd64"
}

variable "os_url" {
  type        = string
  description = "The URL in which the ISO for the OS can be found"
  default     = "https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso"
}

variable "os_locale" {
  type        = string
  description = "The locale of the OS"
  default     = "en_US"
}

variable "network_adapter" {
  type        = string
  description = "The name of the network adapter to use"
  default     = "Wi-Fi"
}

source "hyperv-iso" "ubuntu" {
  iso_url      = var.os_url
  iso_checksum = var.os_checksum
  http_content = {
    "/user-data" = templatefile("./templates/user-data-template.pkr.hcl", {
      username = var.username
      password = var.hashed_password
      hostname = var.username
      locale   = var.os_locale
    })
    "/meta-data" = ""
  }
  boot_command = [
    "c",
    "linux /casper/vmlinuz quiet autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ <enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
  memory = 4096
  cpus   = 2


  vm_name   = var.vm_name
  boot_wait = "10s"
  # https://github.com/hashicorp/packer-plugin-hyperv/issues/65#issuecomment-1603306355
  switch_name      = var.network_adapter
  ssh_username     = var.username
  generation       = 2
  ssh_password     = var.password
  ssh_port         = 22
  ssh_wait_timeout = "1000s"
  shutdown_command = "echo 'vagrant'|sudo -S shutdown -P now"
}

build {
  sources = ["source.hyperv-iso.ubuntu"]


  provisioner "shell" {
    script            = "scripts/update.sh"
    expect_disconnect = true
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /home/vagrant/.ssh",
      "curl -L -o /home/vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub",
      "chown -R vagrant:vagrant /home/vagrant/.ssh",
      "chmod -R go-rwsx /home/vagrant/.ssh"
    ]
  }

  provisioner "shell" {
    script       = "scripts/cleanup.sh"
    pause_before = "120s"
  }

  post-processor "vagrant" {
    output = "ubuntu${var.os_version}.box"
  }
}
