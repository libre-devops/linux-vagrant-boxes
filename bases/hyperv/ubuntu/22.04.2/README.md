# Hyper-V Vagrant Box Creation Using Packer

This repository contains a Packer template, additional scripts, and a PowerShell script that automate the creation of a Vagrant Box for Hyper-V. 

This particular configuration sets up an Ubuntu 22.04.2 base image using the `hyperv-iso` builder. It will download the specified Ubuntu ISO, install it on a Hyper-V virtual machine, set up cloud-init for first boot configurations, perform system updates, configure SSH settings for Vagrant, clean up the system, and finally package it all into a Vagrant box.

### Pre-requisites

Ensure you have the following software installed on your machine:

- [Packer](https://www.packer.io/downloads)
- [Vagrant](https://www.vagrantup.com/downloads)
- [Hyper-V](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-the-hyper-v-role-on-windows-server) (on Windows)
- OpenSSL
- PowerShell

### PowerShell Script

The PowerShell script provided in this repository serves as a glue between Packer and Vagrant. It automates several tasks that otherwise would have to be executed manually.

Here's a high-level overview of what the script does:

1. It generates a random alphanumeric string that is used to name the virtual machine (VM) that is going to be created.

2. It sets up a function to create or confirm the existence of firewall rules for certain port ranges.

3. It gets the checksum of the OS from the provided URL, a prerequisite for Packer.

4. It checks if OpenSSL is installed since the script uses it to hash the default password.

5. It creates/validates firewall rules required for the virtual machine and Packer to operate correctly.

6. It defines a virtual switch for Hyper-V and creates/validates a firewall rule for it.

7. The script then calls the `packer build` command with the required variables, and if this fails, it will remove the VM that was being created.

8. If Packer successfully creates the VM, it will get the SHA256 checksum of the box file and add the box to Vagrant. If the Vagrantfile exists, the script will try to start the new VM with `vagrant up`.

9. If `vagrant up` fails, the script will try to halt and destroy the newly created VM.

### Usage

1. Clone this repository.
2. Run the PowerShell script provided in the repository.

#### Variables



## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hashed_password"></a> [hashed\_password](#input\_hashed\_password) | The hashed password of the default user. You will need to generate this with openssl or mkpasswd on NIX systems | `string` | `"vagrant"` | no |
| <a name="input_network_adapter"></a> [network\_adapter](#input\_network\_adapter) | The name of the network adapter to use | `string` | `"Wi-Fi"` | no |
| <a name="input_os_checksum"></a> [os\_checksum](#input\_os\_checksum) | The checksum of the OS, can be fetched programmatically | `string` | `"5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"` | no |
| <a name="input_os_locale"></a> [os\_locale](#input\_os\_locale) | The locale of the OS | `string` | `"en_US"` | no |
| <a name="input_os_type"></a> [os\_type](#input\_os\_type) | The type of OS, e.g, server-amd64 etc | `string` | `"live-server-amd64"` | no |
| <a name="input_os_url"></a> [os\_url](#input\_os\_url) | The URL in which the ISO for the OS can be found | `string` | `"https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso"` | no |
| <a name="input_os_version"></a> [os\_version](#input\_os\_version) | The version of OS to use | `string` | `"22.04.2"` | no |
| <a name="input_password"></a> [password](#input\_password) | The password of the default user | `string` | `"vagrant"` | no |
| <a name="input_username"></a> [username](#input\_username) | The username of the default user | `string` | `"vagrant"` | no |
| <a name="input_vagrant_box_name"></a> [vagrant\_box\_name](#input\_vagrant\_box\_name) | The name of the vagrant output box | `string` | `"ubuntu-22.04.2.box"` | no |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | The name of the VM | `string` | `"packer-ubuntu22.04.2base"` | no |

## Outputs

No outputs.

#### Scripts

The repository also includes a set of scripts that are run at different stages of the machine image creation process:

- `update.sh` - This script updates the system using apt-get, upgrades the distribution, and then reboots the machine. 
- `cleanup.sh` - This script cleans up the system by removing unused and temporary files, logs, and APT cache.

#### Cloud-init Configuration

The cloud-init configuration used here sets up the system with a username, password, and several essential packages. It also modifies sudoers file to allow passwordless sudo for the default user and enables root login and password authentication for SSH.

### Output

The output from running Packer will be a `.box` file which can be added to Vagrant using the command `vagrant box add path/to/box/file.box --name "my_box"`, replacing "my_box" with a name of your choice.

After this, you can then create a new Vagrantfile and use `my_box` as the box in the configuration. Now you're ready to `vagrant up` your new VM.
