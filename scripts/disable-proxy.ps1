# Disable Windows system proxy
$reg = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
$current = (Get-ItemProperty $reg).ProxyEnable
if ($current -eq 1) {
    Set-ItemProperty $reg ProxyEnable 0
    Write-Host "Proxy disabled"
} else {
    Write-Host "Proxy already disabled"
}
