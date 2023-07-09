source "hyperv-iso" "ubuntu2204" {
  iso_url = "http://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
  iso_checksum_type = "sha256"
  iso_checksum = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
  http_directory = "http"
  boot_command = [
    "<enter><wait>",
    "/install/vmlinuz noapic ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "debian-installer=en_US auto locale=en_US kbd-chooser/method=us ",
    "hostname={{ .Name }} ",
    "fb=false debconf/frontend=noninteractive ",
    "keyboard-configuration/modelcode=SKIP keyboard-configuration/layout=USA ",
    "keyboard-configuration/variant=USA console-setup/ask_detect=false ",
    "initrd=/install/initrd.gz -- <enter>"
  ]
  boot_wait = "10s"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_port = 22
  ssh_wait_timeout = "10000s"
  shutdown_command = "echo 'vagrant'|sudo -S shutdown -P now"
}

build {
  sources = ["source.hyperv-iso.ubuntu2204"]

  provisioner "shell" {
    script = "scripts/update.sh"
  }

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }

  provisioner "shell" {
    script = "scripts/minimize.sh"
  }

  post-processor "vagrant" {
    output = "ubuntu2204.box"
  }
}
