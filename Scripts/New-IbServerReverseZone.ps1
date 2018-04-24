function New-IbServerReverseZone {
    param (
        $NetworkCIDR = '10.136.17.0/24',
        $Site = 'Burbank',
        $NameServerGroup = 'Arena',
        $View = 'default',
        $ZoneFormat = 'IPV4'
    )

    $jsonNetwork24 = @"
{
    "allow_gss_tsig_for_underscore_zone":  false,
    "allow_gss_tsig_zone_updates":  true,
    "allow_update_forwarding":  true,
    "comment": "$Site",
    "ddns_principal_tracking":  true,
    "ddns_restrict_protected":  true,
    "ddns_restrict_secure":  true,
    "ddns_restrict_static":  true,
    "disable":  false,
    "disable_forwarding":  false,
    "extattrs":  {
                        "Site":  {
                                    "value":  "$Site"
                                },
                        "Status":  {
                                    "value":  "keep"
                                }
                    },
    "fqdn":  "$NetworkCIDR",
    "ns_group":  "$NameServerGroup",
    "use_allow_update":  true,
    "use_allow_update_forwarding":  true,
    "use_ddns_principal_security":  true,
    "use_ddns_restrict_protected":  true,
    "use_ddns_restrict_static":  true,
    "view":  "$View",
    "zone_format":  "$ZoneFormat"
}
"@
    $objnetwork24 = $jsonNetwork24 | ConvertFrom-Json
    New-IBObject -ObjectType zone_auth -IBObject $objnetwork24
}


function New-IbServerReverseZone {
    param (
        $NetworkCIDR = '10.136.17.0/24',
        $Site = 'Burbank',
        $NameServerGroup = 'Arena',
        $View = 'default',
        $ZoneFormat = 'IPV4'
    )

    $objnetwork24  = [pscustomobject]@{
        allow_gss_tsig_for_underscore_zone = $false
        allow_gss_tsig_zone_updates = $true
        allow_update_forwarding = $true
        comment = $Site
        ddns_principal_tracking = $true
        ddns_restrict_protected = $true
        ddns_restrict_secure = $true
        ddns_restrict_static = $true
        disable = $false
        disable_forwarding = $false
        fqdn = $NetworkCIDR
        ns_group = $NameServerGroup
        use_allow_update = $true
        use_allow_update_forwarding = $true
        use_ddns_principal_security = $true
        use_ddns_restrict_protected = $true
        use_ddns_restrict_static = $true
        view = $View
        zone_format = $ZoneFormat
        extattrs = [pscustomobject]@{
            Site = [pscustomobject]@{value = $Site}
            Status = [pscustomobject]@{value = 'keep'}
        }
    }

    New-IBObject -ObjectType zone_auth -IBObject $objnetwork24
}