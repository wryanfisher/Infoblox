$burbankInfobloxMember = '10.136.8.10','10.136.8.11','10.136.8.12'
$corpInfobloxGridmaster = '10.131.62.170','10.131.130.26'
$corpInfobloxDhcpfailover = '10.131.62.176'
$infobloxVpn = 2114,1194
$infobloxDhcpfo = 647,7911

$i = 0
foreach ($member in $burbankInfobloxMember) {
    foreach ($gm in $corpInfobloxGridmaster) {
        foreach ($port in $infobloxVpn) {
            $i += 1;"connection $i source $member dest $gm UDP $port"
            $i += 1;"connection $i source $gm dest $member UDP $port"
        }
        $i += 1;"connection $i source $gm dest $member TCP 7911"
    }
    $i += 1;"connection $i source $member dest $corpInfobloxDHcpfailover TCP 647"
}
