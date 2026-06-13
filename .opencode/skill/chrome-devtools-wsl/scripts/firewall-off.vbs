Set UAC = CreateObject("Shell.Application")
UAC.ShellExecute "cmd.exe", "/c netsh advfirewall firewall add rule name=""WSL Chrome CDP"" dir=in action=allow protocol=TCP localport=9222 && echo 已放行 Chrome CDP 端口 9222 && pause", "", "runas", 1
