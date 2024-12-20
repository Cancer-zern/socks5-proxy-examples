#!/bin/bash

# Stop the Xray service
sudo systemctl stop xray

# Remove the Xray binary
sudo rm /usr/local/bin/xray 2> /dev/null

# Remove the Xray configuration file
sudo rm /usr/local/etc/xray/config.json 2> /dev/null

# Remove the Xray service file
sudo rm /etc/systemd/system/xray.service 2> /dev/null

# Reload the systemd daemon
sudo systemctl daemon-reload

# Remove logs
sudo rm -rf /var/log/xray

# Remove job in cron
sudo sed -i '/Xray/d' /etc/crontab