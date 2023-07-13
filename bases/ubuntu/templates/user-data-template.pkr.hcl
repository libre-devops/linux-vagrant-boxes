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
    late-commands:
        - echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/vagrant
        - chmod 440 /target/etc/sudoers.d/vagrant
        - apt-get update


