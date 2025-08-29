$TmpFolder="C:\tmp\Xray-windows-64"
$XrayFolder="C:\Xray-windows-64"
$env:Path += ";$XrayFolder"
$env:Path += ";C:\temp\openssl\openssl-1.1\x64\bin"
$opensslUrl='https://download.firedaemon.com/FireDaemon-OpenSSL/openssl-1.1.1w.zip'
$opensslBasePath="C:\tmp"
$opensslPathDest="C:\tmp\openssl"


$name = 'Xray-core' | %{ If($Entry = Read-Host "Enter the ServerName [default name: ($_)]"){$Entry} Else {$_} }
$email="user1@myserver"
$port = '443' | %{ If($Entry = Read-Host "Enter vless port [default port: ($_)]"){$Entry} Else {$_} }
$ssport = '3389' | %{ If($Entry = Read-Host "Enter ss port [default port: ($_)]"){$Entry} Else {$_} }
$sni = 'microsoft.com' | %{ If($Entry = Read-Host "Enter SNI [default sni: ($_)]"){$Entry} Else {$_} }


echo "# Install Xray"
New-Item -Path "$TmpFolder" -ItemType Directory -Force | Out-Null
Remove-Item -Path "$TmpFolder\*" -Force
curl https://github.com/XTLS/Xray-core/releases/latest/download/Xray-windows-64.zip -o $TmpFolder\Xray-windows-64.zip
Expand-Archive -Path "$TmpFolder\Xray-windows-64.zip" -DestinationPath "$TmpFolder" -Force
Remove-Item $TmpFolder\Xray-windows-64.zip
Get-Process -Name "xray" -ErrorAction SilentlyContinue | Stop-Process -Force


if (Test-Path -Path $XrayFolder) {
	Copy-Item -Path "$TmpFolder\*" -Destination "C:\Xray-windows-64" -Force
} else {
	New-Item -Path "$XrayFolder" -ItemType Directory -Force | Out-Null
	Copy-Item -Path "$TmpFolder\*" -Destination "C:\Xray-windows-64" -Force
}
Remove-Item -Path "$TmpFolder\*" -Force


echo "# Configuration"
curl https://raw.githubusercontent.com/Cancer-zern/socks5-proxy-examples/main/Xray/installation/config.json -o $XrayFolder\config.json
Invoke-RestMethod $opensslUrl -OutFile $opensslBasePath\openssl.zip
Expand-Archive $opensslBasePath\openssl.zip -DestinationPath $opensslPathDest -Force

function New-RandomPasswordBase64 {
    Param (
        [int]$Length = 16,
        [switch]$IncludeSpecialCharacters
    )

    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    if ($IncludeSpecialCharacters) {
        $chars += '!@#$%^&*()-_=+'
    }

    $password = -join (Get-Random -InputObject $chars.ToCharArray() -Count $Length)
    $base64Password = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($password))

    return $base64Password
}

$keys=(xray.exe x25519)
$pk=($keys | Where-Object{$_ -Like "Private key:*"} | %{($_ -split "\s+")[2]})
$pub=($keys | Where-Object{$_ -Like "Public key:*"} | %{($_ -split "\s+")[2]})
$serverIp=(Invoke-WebRequest ifconfig.me/ip).Content.Trim()
$uuid=(xray.exe uuid)
$shortId=$(openssl rand -hex 8)
$password=New-RandomPasswordBase64
$jsonContent = Get-Content -Path "$XrayFolder/config.json" | ConvertFrom-Json
$jsonContent.inbounds[0].port = $ssport
$jsonContent.inbounds[0].settings.password = $password
$jsonContent.inbounds[1].port = $port
$jsonContent.inbounds[1].settings.clients[0].email = $email
$jsonContent.inbounds[1].settings.clients[0].id = $uuid
$jsonContent.inbounds[1].streamSettings.realitySettings.dest = $sni + ":443"
$jsonContent.inbounds[1].streamSettings.realitySettings.serverNames += $sni
#$jsonContent.inbounds[1].streamSettings.realitySettings.serverNames += "www."+$sni
$jsonContent.inbounds[1].streamSettings.realitySettings.privateKey = $pk
$jsonContent.inbounds[1].streamSettings.realitySettings.shortIds += $shortId
$updatedJson = $jsonContent | ConvertTo-Json -Depth 10
Set-Content -Path "$XrayFolder\config.json" -Value $updatedJson


echo "# Firewall"
netsh advfirewall firewall delete rule name="Xray-In-Vless" | Out-Null
netsh advfirewall firewall add rule name="Xray-In-Vless" dir=in action=allow program="$XrayFolder\xray.exe" enable=yes protocol=TCP localport=$port | Out-Null
netsh advfirewall firewall delete rule name="Xray-Out-Vless" | Out-Null
netsh advfirewall firewall add rule name="Xray-Out-Vless" dir=out action=allow program="$XrayFolder\xray.exe" enable=yes protocol=TCP localport=$port | Out-Null

netsh advfirewall firewall delete rule name="Xray-In-Ss" | Out-Null
netsh advfirewall firewall add rule name="Xray-In-Ss" dir=in action=allow program="$XrayFolder\xray.exe" enable=yes protocol=TCP localport=$ssport | Out-Null
netsh advfirewall firewall add rule name="Xray-In-Ss" dir=in action=allow program="$XrayFolder\xray.exe" enable=yes protocol=UDP localport=$ssport | Out-Null
netsh advfirewall firewall delete rule name="Xray-Out-Ss" | Out-Null
netsh advfirewall firewall add rule name="Xray-Out-Ss" dir=out action=allow program="$XrayFolder\xray.exe" enable=yes protocol=TCP localport=$ssport | Out-Null
netsh advfirewall firewall add rule name="Xray-Out-Ss" dir=out action=allow program="$XrayFolder\xray.exe" enable=yes protocol=UDP localport=$ssport | Out-Null


echo "# ScheduledTask"
Stop-ScheduledTask -TaskName "Xray-Core" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Xray-Core" -Confirm:$false -ErrorAction SilentlyContinue
$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $XrayFolder\xray_no_window.ps1" -WorkingDirectory $XrayFolder
$taskTrigger1 = New-ScheduledTaskTrigger -AtStartup
$taskTrigger2 = New-ScheduledTaskTrigger -Daily -At "12:00 AM"
$taskTrigger3 = New-ScheduledTaskTrigger -Once -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hour 1) -RepetitionDuration (New-TimeSpan -Day 1)
$taskTrigger2.Repetition = $taskTrigger3.Repetition
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "Xray-Core" -Action $taskAction -Trigger $taskTrigger1,$taskTrigger2 -Principal $principal | Out-Null
Start-ScheduledTask -TaskName "Xray-Core"


# Params for Export
Install-Module -Name QrCodes
Import-Module QrCodes

$url="vless://"+$uuid+"@"+$serverIp+":"+$port+"?security=reality&sni="+$sni+"&alpn=h2&fp=chrome&pbk="+$pub+"&sid="+$shortId+"&type=tcp&flow=xtls-rprx-vision&encryption=none#"+$name
$ssurl="ss://2022-blake3-chacha20-poly1305:"+$password+"@"+$serverIp+":"+$ssport+"#"+$name



echo ""
echo "###VLESS Params###"
echo ""
echo $url
ConvertTo-QrCode -InputObject $url | Format-QRCode
echo ""
echo "###SS Params###"
echo ""
echo $ssurl
ConvertTo-QrCode -InputObject $ssurl | Format-QRCode
echo ""
echo "ALL DONE"