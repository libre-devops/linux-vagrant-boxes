#!/usr/bin/env bash
set -e
set -v

# Zero out the free space to save space in the final image
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY

# Clean up log files
sudo find /var/log -type f | while read f; do echo -ne '' | sudo tee $f; done

# Remove the contents of /tmp and /var/tmp
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Force locale to en_US.UTF-8
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
