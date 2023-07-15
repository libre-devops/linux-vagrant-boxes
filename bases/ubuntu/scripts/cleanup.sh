#!/usr/bin/env bash
set -e
set -v

# Install necessary tools
sudo apt-get install -y deborphan

# Clean up APT
sudo apt-get autoremove -y
sudo apt-get autoclean -y
sudo apt-get clean -y

# Remove orphaned packages
sudo deborphan | xargs sudo apt-get -y remove --purge

# Remove old kernel modules
sudo rm -rf /lib/modules/$(uname -r)

# Remove unused config files
sudo dpkg --purge $(COLUMNS=200 dpkg -l | grep "^rc" | tr -s ' ' | cut -d ' ' -f 2)

# Remove documentation, manuals and locales
sudo rm -rf /usr/share/doc/*
sudo rm -rf /usr/share/man/*
sudo rm -rf /usr/share/info/*
sudo rm -rf /usr/share/lintian/*
sudo rm -rf /usr/share/linda/*
sudo rm -rf /var/cache/man/*

# Remove logs
sudo rm -rf /var/log/*
sudo rm -rf /var/cache/apt/*

# Remove old Temp Files
sudo rm -rf /tmp/*

echo "Done. The system requires a reboot."
