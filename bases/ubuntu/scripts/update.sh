#!/usr/bin/env bash
set -e
set -v

# Update the system
sudo apt-get update
sudo apt-get upgrade -y

# Install basic utilities
sudo apt-get install -y curl wget git
