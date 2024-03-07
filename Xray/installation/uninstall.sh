#!/bin/bash

# Stop the Xray service
sudo systemctl stop xray

# Remove the Xray binary
sudo rm /usr/local/bin/xray

# Remove the Xray configuration file
sudo rm /usr/local/etc/xray/config.json

# Remove the Xray service file
sudo rm /etc/systemd/system/xray.service

# Reload the systemd daemon
sudo systemctl daemon-reload

# Remove logs
sudo rm -rf /var/log/xray