$XrayFolder="C:\Xray-windows-64"
$TmpFolder="C:\tmp"

echo "# Kill process and remove folders"
Get-Process -Name "xray" -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item -Path "$XrayFolder" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$TmpFolder" -Force -ErrorAction SilentlyContinue

echo "# Remove Tasks from ScheduledTask"
Stop-ScheduledTask -TaskName "Xray-Core" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Xray-Core" -Confirm:$false -ErrorAction SilentlyContinue


echo "# Remove Rules from Firewall"
netsh advfirewall firewall delete rule name="Xray-In-Vless" | Out-Null
netsh advfirewall firewall delete rule name="Xray-Out-Vless" | Out-Null
netsh advfirewall firewall delete rule name="Xray-In-Ss" | Out-Null
netsh advfirewall firewall delete rule name="Xray-Out-Ss" | Out-Null