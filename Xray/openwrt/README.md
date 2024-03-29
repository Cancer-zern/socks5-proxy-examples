# Functionality
Downloading Xray-core to /tmp and run xray-core with configuration file:
- Downloading xray-core to /tmp
- Apply file permissions
- Run with --config=/etc/xray/config.json

# Requrements
- OpenWRT 19.07 and newer
- create init.d script to /etc/init.d/xray
- add configuration file to path /etc/xray/config.json
- Firewall Open port for vless 443/tcp [port and protocol as in config.json]
- OpenWRT System -> Startup -> xray [change from "Disabled" to "Enabled" and then Start]