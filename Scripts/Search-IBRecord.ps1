Import-Module .\infoblox\Infoblox.psm1

Get-IBConfig

New-IBSession -Credential (Get-Credential rfisher.ib)

$topic = 'keystone'

$filter = [pscustomobject] @{
    object='canonical'
    operator='~='
    filter=$topic
}
Get-IBObject -Object record:cname -Filters $filter

$filter = [pscustomobject] @{
    object='name'
    operator='~='
    filter=$topic
}
Get-IBObject -Object record:cname -Filters $filter

$filter = [pscustomobject] @{
    object='name'
    operator='~='
    filter=$topic
}
Get-IBObject -Object record:host -Filters $filter

$filter = [pscustomobject] @{
    object='comment'
    operator='~='
    filter=$topic
}
Get-IBObject -Object record:host -Filters $filter

Get-IBObject -Object record:host -Properties name,aliases |
    ? aliases -match $topic

$filter = [pscustomobject] @{
    object='comment'
    operator='~='
    filter=$topic
}
Get-IBObject -Object record:ptr -Filters $filter

$filter = [pscustomobject] @{
    object='ptrdname'
    operator='~='
    filter=$topic
}
Get-IBObject -Object record:ptr -Filters $filter



# SRV
# TXT
 Get-IBObject -Object record:cname -Filters $filter | ? canonical -Match 'vip-.*' | % canonical | Resolve-DnsName -Server cdc-utl-107
 