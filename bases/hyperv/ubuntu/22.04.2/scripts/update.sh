#!/usr/bin/env bash
set -xe

# Update the system
sudo apt-get update
sudo apt-get dist-upgrade -y
sleep 60 && sudo shutdown -r now &
exit 0
