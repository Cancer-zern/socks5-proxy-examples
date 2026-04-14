$Tmp="C:\tmp"


Remove-Item -Path "$Tmp\*" -Recurse -Force
New-Item -Path "$Tmp" -ItemType Directory -Force
curl https://github.com/XTLS/Xray-core/releases/latest/download/Xray-windows-64.zip -o $Tmp\Xray-windows-64.zip
Expand-Archive -Path "$Tmp\Xray-windows-64.zip" -DestinationPath "$Tmp"
Remove-Item $Tmp\Xray-windows-64.zip
Get-Process -Name "xray" -ErrorAction SilentlyContinue | Stop-Process -Force
Copy-Item -Path "$Tmp\*" -Destination "C:\Xray-windows-64" -Force
Remove-Item -Path "$Tmp\*" -Recurse -Force

schtasks /Run /TN Xray-Core