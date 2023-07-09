#!/usr/bin/env bash
set -e
set -v

# Clean up APT
sudo apt-get autoremove -y
sudo apt-get autoclean -y
sudo apt-get clean -y

# Zero out the free space to save space in the final image
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY
