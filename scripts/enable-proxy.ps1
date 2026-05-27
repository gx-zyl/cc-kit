# Restore Windows system proxy
$reg = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
Set-ItemProperty $reg ProxyEnable 1
Set-ItemProperty $reg ProxyServer '127.0.0.1:9910'
Write-Host "Proxy restored (127.0.0.1:9910)"
