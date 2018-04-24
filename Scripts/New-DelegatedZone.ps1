function New-DelegatedZone {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string]$ZoneName,
        [parameter(Mandatory=$true)]
        [string]$Comment,
        [parameter(Mandatory=$false,ParameterSetName='delegateobject')]
        [ValidateNotNullOrEmpty()]
        $DelegateTo = @(
            @{
                name = 'se1-bons-corpdns-vip01.battle.net'
                address = '10.47.34.216'
            },
            @{
                name = 'se1-bons-corpdns-vip02.battle.net'
                address = '10.47.34.217'
            }
        ),
        [parameter(mandatory=$false,parametersetname='delegatestring')]
        [ValidateNotNullOrEmpty()]
        [string]$ServerString
    )

    begin {
        try {
            if ($ServerString) {
                $DelegateTo = $ServerString -split "\r+\n+|,+|;+|\s+" |
                            Resolve-DnsName -erroraction 'Stop'  |
                            ? type -eq 'a' |
                            select @{n='name';e={$_.Name}},@{n='address';e={$_.IPADdress}}
            }
        }
        catch {
            throw $_
        }
        finally {}
    }

    process {
        $zoneObject = @{
            fqdn = $zoneName
            delegate_to = $DelegateTo
            comment = $Comment
        }
        Write-Verbose -message $($zoneObject | convertto-json)
        New-IBObject -ObjectType 'zone_delegated' -IBObject $zoneObject
    }
    
    end {
    }
}
