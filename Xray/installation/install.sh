#!/bin/bash

# Update package index and install dependencies
sudo apt-get update
sudo apt-get install -y jq openssl qrencode pwgen


# Extract the desired variables using jq
name=UK
email=user1@myserver
port=443
ssport=3389
sni=microsoft.com

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

json=$(curl -s https://raw.githubusercontent.com/Cancer-zern/socks5-proxy-examples/main/Xray/installation/config.json)

keys=$(xray x25519)
pk=$(echo "$keys" | awk '/Private key:/ {print $3}')
pub=$(echo "$keys" | awk '/Public key:/ {print $3}')
serverIp=$(curl -s ipv4.wtfismyip.com/text)
uuid=$(xray uuid)
shortId=$(openssl rand -hex 8)
password=$(pwgen 31 1 | base64)

url="vless://$uuid@$serverIp:$port?security=reality&sni=$sni&alpn=h2&fp=chrome&pbk=$pub&sid=$shortId&type=tcp&flow=xtls-rprx-vision&encryption=none#$name"
ssurl="ss://2022-blake3-chacha20-poly1305:$password@$serverIp:$ssport#$name"


newJson=$(echo "$json" | jq \
    --arg pk "$pk" \
    --arg uuid "$uuid" \
    --arg port "$port" \
    --arg sni "$sni" \
    --arg email "$email" \
    --arg password "$password" \
    '.inbounds[0].port= '"$(expr "$ssport")"' |
     .inbounds[0].settings.password = $password |
     .inbounds[1].port= '"$(expr "$port")"' |
     .inbounds[1].settings.clients[0].email = $email |
     .inbounds[1].settings.clients[0].id = $uuid |
     .inbounds[1].streamSettings.realitySettings.dest = $sni + ":443" |
     .inbounds[1].streamSettings.realitySettings.serverNames += ["'$sni'", "www.'$sni'"] |
     .inbounds[1].streamSettings.realitySettings.privateKey = $pk |
     .inbounds[1].streamSettings.realitySettings.shortIds += ["'$shortId'"]')

echo "$newJson" | sudo tee /usr/local/etc/xray/config.json >/dev/null
sudo systemctl restart xray

echo "$url"

qrencode -s 120 -t ANSIUTF8 "$url"
qrencode -s 50 -o qr.png "$url"

echo "$ssurl"
qrencode -s 120 -t ANSIUTF8 "$ssurl"
qrencode -s 50 -o ssqr.png "$ssurl"

if [ `grep -c 'net.core.default_qdisc=fq' /etc/sysctl.conf` == 0 ]
then 
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.core.default_qdisc=fq - added"
else 
    echo "net.core.default_qdisc=fq - exist"
fi

if [ `grep -c 'net.ipv4.tcp_congestion_control=bbr' /etc/sysctl.conf` == 0 ]
then 
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr - added"
else 
    echo "net.ipv4.tcp_congestion_control=bbr - exist"
fi

sysctl -p


exit 0