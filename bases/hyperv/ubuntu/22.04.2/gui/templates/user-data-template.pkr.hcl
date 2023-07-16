#cloud-config
autoinstall:
    version: 1
    locale: ${locale}
    identity:
        hostname: ${hostname}
        username: ${username}
        password: ${password}
    ssh:
        install-server: yes
    packages:
        - build-essential
        - ntp
        - curl
        - sudo
        - sed
        - nano
        - net-tools
        - linux-virtual
        - linux-cloud-tools-virtual
        - linux-tools-virtual
        - open-vm-tools
    late-commands:
        - echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/vagrant
        - chmod 440 /target/etc/sudoers.d/vagrant
        - echo "root:vagrant" | chpasswd
        - apt-get update
        - sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        - sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /target/etc/ssh/sshd_config
        - systemctl restart sshd






