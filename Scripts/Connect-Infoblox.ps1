ipmo Posh-IBWAPI -Force
$grid = 'infoblox.blizzard.net'
$cred = Get-Credential rfisher.ib
Set-IBWAPIConfig -WAPIHost $grid -WAPIVersion 'latest' -Credential $cred
