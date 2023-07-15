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

source "hyperv-iso" "ubuntu2204" {
  iso_url         = "http://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
  iso_checksum    = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
  http_content = {
    "/user-data" = templatefile("./templates/user-data-template.pkr.hcl", {
      username        = var.username
      password        = var.hashed_password
      hostname        = var.username
      locale          = "en_US"
    })
    "/meta-data" = ""
  }
  boot_command         = [
    "c",
    "linux /casper/vmlinuz quiet autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ <enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
  memory = 4096
  cpus   = 2


  vm_name           = var.vm_name
  boot_wait         = "10s"
  # https://github.com/hashicorp/packer-plugin-hyperv/issues/65#issuecomment-1603306355
  switch_name       = "Wi-Fi"
  ssh_username      = var.username
  generation        = 2
  ssh_password      = var.password
  ssh_port          = 22
  ssh_wait_timeout  = "1000s"
  shutdown_command  = "echo 'vagrant'|sudo -S shutdown -P now"
}

build {
  sources = ["source.hyperv-iso.ubuntu2204"]


  provisioner "shell" {
    script            = "scripts/update.sh"
    expect_disconnect = true
  }

  provisioner "shell" {
    script       = "scripts/cleanup.sh"
    pause_before = "120s"
  }

  post-processor "vagrant" {
    output = "ubuntu2204.box"
  }
}
