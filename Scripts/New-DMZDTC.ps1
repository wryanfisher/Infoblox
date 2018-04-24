$Grid = 'infoblox.blizzard.net'
[pscredential]$Credential = $(Get-Credential)
ipmo Posh-IBWAPI -Force
Set-IBWAPIConfig -WAPIHost $grid -WAPIVersion 'latest' -Credential $cred

function New-IBZone {
    param (
        [string]$FQDN,
        [string]$View = 'default',
        [int]$TTL = 0,
        [int]$Expire = 14400,
        [int]$NegativeTTL = 15,
        [int]$Refresh = 180,
        [int]$Retry = 60,
        [string]$NameServerGroup = 'Internal DNS',
        [string]$Comment = 'TEST ZONE PLEASE DELETE.'

    )
    try {
        $Zone = Get-IBObject -ObjectType zone_auth -Filters "fqdn=$FQDN","view=$View" -ReturnBaseFields
        if (-not $Zone) {
            $structAddressac =  @(@{_struct='addressac'; address='Any'; permission='ALLOW'})
            $newZone = [pscustomobject]@{
                fqdn = $FQDN
                view = $view
                soa_default_ttl = $TTL
                soa_expire = $Expire
                soa_negative_ttl = $NegativeTTL
                soa_refresh = $Refresh
                soa_retry = $Retry
                ns_group = $NameServerGroup
                comment = $Comment
                allow_query = $structAddressac
                use_allow_query = $True
            }
            $zone = New-IBObject -ObjectType 'zone_auth' -IBObject $newZone -ReturnBaseFields
        }
        return $zone
    }
    catch {
        throw
    }
}

function New-DMZDTC {
    param (
        $FQDN,
        $ProjectTag
    )

    # Connect to Grid
    $views = @('default','dmz')
    $zones = @()
    foreach ($View in $Views) {
        # Create zone for DTC (So forwarding zones get correct TTL of 0)
        # Create zone in default view
        # Create zone in DMZ view
        # Create CNAME to DTC zone
        # create CNAME for service as needed
        $zones += New-IBZone -FQDN $FQDN -View $View -NameServerGroup 'DTC' -Comment "New-DMZDTC - $(get-date)"

    }

    # Create DTC LBDN record: 
        # Create servers
        # create pool
        # create DTC record
            # Name: lbdn-xd2-project-service
            # Pattern: zone fqdn
            # associated zones: $zones._ref
            # associated zones default TTL to 0
            # LB Method: Ratio

}
