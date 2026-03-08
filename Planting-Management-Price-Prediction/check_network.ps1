Get-NetIPAddress -AddressFamily IPv4 | Select-Object IPAddress, InterfaceAlias | Out-File -FilePath network_info.txt
Get-NetTCPConnection -LocalPort 7001 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, State | Out-File -FilePath port_info.txt
