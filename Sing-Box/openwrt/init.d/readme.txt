chmod +x /etc/init.d/sing-box


mkdir /etc/sing-box/
cp config.json /etc/sing-box/config.json
sing-box run -c /etc/sing-box/config.json


/etc/init.d/sing-box enable
/etc/init.d/sing-box start