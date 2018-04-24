function New-ForwardingZone {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string]$ZoneName,
        [parameter(Mandatory=$true)]
        [string]$Comment,
        $ForwardTo = @(
            @{
                name = 'se1-bons-corpdns-vip01.battle.net'
                address = '10.47.34.216'
            },
            @{
                name = 'se1-bons-corpdns-vip02.battle.net'
                address = '10.47.34.217'
            }
            ),
        $ForwardingServers = 'BIIS Forwarders'       
    )
            
    begin {
    }
    
    process {
        $zoneObject = @{
            fqdn = $zoneName
            forward_to = $forwardTo
            forwarders_only = $true
            ns_group = $forwardingServers
            comment = $Comment
        }
        New-IBObject -ObjectType zone_forward -IBObject $zoneObject
    }
    
    end {
    }
}
