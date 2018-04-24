# Notes working with the GUI, ideas to update etc.
# see also notes.txt

# Create an authenticated session and stores it in the named Variable
$baseURI = 'https://infoblox.blizzard.net/wapi/v2.6.1'
$URI = "$baseURI/grid"
iwr -Uri $URI -SessionVariable TempSession2 -Method Get -Credential (get-credential)

# Get the Netowrk object with a comment matching 419
iwr -ContentType 'application/json' -Method GET -WebSession $TempSession2 -Uri "$baseURI/network?comment~=419"

# Get the schema for the Netowrk object
$netSchemaJSON = iwr -ContentType 'application/json' -Method GET -WebSession $TempSession2 -Uri "$baseURI/network?_schema" | % content

# Display the schema
$netSchemaJSON | ConvertFrom-Json|% fields | sort name | ft -auto

# Find DNS delegations
Get-IBObject -Object 'zone_delegated' -Properties  display_domain,fqdn,delegate_to,zone_format | ft -auto display_domain,fqdn,zone_format

# Get a host record
$URI = "$baseURI/record:host?name:=uscapw-sdev001.corp.blizzard.net&_return_fields=aliases"
iwr -ContentType 'application/json' -Method GET -WebSession $TempSession2 -Uri $URI

# Update Aliases
# $EncodedURL = [System.Web.HttpUtility]::UrlEncode($URL)
# URL/CGI args, x-www-form-urlencoded:
# Use %xx encoding for “%”, ”;”, “/”, ”?”, ”:”, “@”, “&”, “=”, “+”, “$”, ”,” and ” ” (a space)
$gethost = iwr -ContentType 'application/json' -Method GET -WebSession $TempSession2 -Uri "$baseURI/record:host?name=uscapw-sdev001.corp.blizzard.net&_return_fields%2B=aliases"
$content = $gethost.Content | ConvertFrom-Json
$ref = $content._ref
$URI = "$baseURI/$ref"
$alias = $content | select aliases
$alias.aliases += 'dev-ambassadorassets.corp.blizzard.net'
$newAliases = $alias | ConvertTo-Json

iwr -ContentType 'application/json' -Method PUT -WebSession $TempSession2 -Uri $uri -Body $newAliases


# HOWTO Update an Alias
# Resolve the alias






### Testing for Vincent
# In GUI:
# Create a A record with PTR
# Remove the A record
# Check if PTR is removed.
# In API:
# Create a A record
# Create PTR record
# Remove the A record
# Check if PTR is removed.
# ! IS this an alert?
# ? is this a question?
# TODO: THis is a todo statement

# Create an authenticated session and stores it in the named Variable
$cred = Get-Credential 'rfisher.ib'
$baseURI = 'https://infoblox.blizzard.net/wapi/v2.6.1'
$URI = "$baseURI/grid"
iwr -Uri $URI -SessionVariable TempSession2 -Method Get -Credential $cred | Out-Null





function Get-IBRecordA {
    param (
        [String]$Name,
        [Switch]$AsJSON
    )
    $URI = "$baseURI/record:a?name=$name"
    $result = iwr -ContentType 'application/json' -Method GET -WebSession $TempSession2 -Uri $URI
    if ($AsJSON) {
        $result.content
    } else {
        $result.content | ConvertFrom-Json
    }
}
Get-IBRecordA ptr-removal-test-01.test.lab | fl 
Get-IBRecordA ptr-removal-test-01.test.lab -AsJSON


$URI = "$baseURI/search?search_string~=ptr-removal-test&objtype=record%3aa&objtype=record%3aptr"
$URI = "$baseURI/search?search_string~=10.254.254.69"
iwr -SessionVariable TempSession2 `
    -Credential $cred `
    -Method Get `
    -ContentType 'application/json' `
    -Uri $URI |
    % content |
    ConvertFrom-Json
    
$URI = "$baseURI/search?address=10.254.254.69"
iwr -SessionVariable TempSession2 `
    -Credential $cred `
    -Method Get `
    -ContentType 'application/json' `
    -Uri $URI |
    % content |
    ConvertFrom-Json
go

### Test the remove_associated_ptr function
# Create an authenticated session and stores it in the named Variable
$cred = Get-Credential
$baseURI = 'https://infoblox.blizzard.net/wapi/v2.6.1'
$URI = "$baseURI/grid"
iwr -Uri $URI -SessionVariable TempSession2 -Method Get -Credential $cred | Out-Null

# Create a A record    
$newA = [PSCustomObject]@{
    ipv4addr = '10.254.254.69'
    name = 'ptr-removal-test-02.test.lab'
} | ConvertTo-Json    
$URI = "$baseURI/record:a"
iwr -SessionVariable TempSession2 `
-Credential $cred `
-Method Post  `
-ContentType 'application/json'  `
-Uri $URI `
-Body $newA

# Create PTR record
$newPTR = [PSCustomObject]@{
    ipv4addr = '10.254.254.69'
    ptrdname = 'ptr-removal-test-02.test.lab'
} | ConvertTo-Json    
$URI = "$baseURI/record:ptr"
iwr -SessionVariable TempSession2 `
-Credential $cred `
-Method Post `
-ContentType 'application/json' `
-Uri $URI `
-Body $jsonPTR

# search for both records
$URI = "$baseURI/search?search_string~=10.254.254.69"
$result = iwr -SessionVariable TempSession2 `
-Credential $cred `
-Method Get `
-ContentType 'application/json' `
-Uri $URI |
% content |
ConvertFrom-Json
$result
$ref = $result |? _ref -match '^record:a' |% _ref

# Remove the A record
$URI = "{0}/{1}?remove_associated_ptr=true" -f $baseURI,$ref
iwr -SessionVariable TempSession2 `
-Credential $cred `
-Method DELETE `
-ContentType 'application/json' `
-Uri $URI |
% content |
ConvertFrom-Json

# Check if PTR is removed.
$URI = "$baseURI/search?search_string~=10.254.254.69"
$result = iwr -SessionVariable TempSession2 `
    -Credential $cred `
    -Method Get `
    -ContentType 'application/json' `
    -Uri $URI |
    % content |
    ConvertFrom-Json
$result


###################################################################################
###################################################################################
###################################################################################
##### Do it with Posh-IBWAPI
# To install from the PS Gallery run command:
# Install-Module Posh-IBWAPI
ipmo Posh-IBWAPI -Force
$grid = 'infoblox.blizzard.net'
$cred = Get-Credential rfisher.ib
Set-IBWAPIConfig -WAPIHost $grid -WAPIVersion 'latest' -Credential $cred

$ip = '10.254.254.70'
$rname = 'ptr-removal-test-03.test.lab'

# Create A record
$newA = [PSCustomObject]@{
    ipv4addr = $ip
    name = $rname
}
New-IBObject -ObjectType 'record:a' -IBObject $newA

# Create PTR record
$newPTR = [PSCustomObject]@{
    ipv4addr = $ip
    ptrdname = $rname
}
New-IBObject -ObjectType 'record:ptr' -IBObject $newPTR

# Find the existing records
Get-IBObject -ObjectType 'record:a' -Filters "name=$rname" -ReturnAllFields
Get-IBObject -ObjectType "record:ptr" -Filters "ptrdname=$rname" -ReturnAllFields

# Remove the A record and PTR record
Get-IBObject -ObjectType 'record:a' -Filters "name=$rname" | Remove-IBObject -DeleteArgs "remove_associated_ptr=true"

# Look for the records. Returns nothing as they do not exist.
Get-IBObject -ObjectType 'record:a' -Filters "name=$rname" -ReturnAllFields
Get-IBObject -ObjectType "record:ptr" -Filters "ptrdname=$rname" -ReturnAllFields

###################################################################################

Get-IBObject -ObjectType "search" -Filters "name~=rfisher" -Verbose


# Get Zone.
$URI = "$baseURI/zone_auth?fqdn=murky-dtc.xd2.blizzdmz.net&_return_fields=allow_query"
$result = iwr -SessionVariable TempSession2 `
    -Credential $cred `
    -Method Get `
    -ContentType 'application/json' `
    -Uri $URI |
    % content
$result

# Add extra cnames
$cnames = @(
[pscustomobject]@{view='dmz';name='oauth-us.web.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='dmz';name='dev.depot.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='dmz';name='shop-live-us.web.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='dmz';name='login-live-us.web.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='dmz';name='login-qa-us.web.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='dmz';name='partner.apidev.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='dmz';name='apigw-stable-us.apidev.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='dmz';name='dev8.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='dmz';name='login-qa-us.web.blizzard.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='default';name='oauth-us.web.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='default';name='dev.depot.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='default';name='shop-live-us.web.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='default';name='login-live-us.web.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='default';name='login-qa-us.web.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='default';name='partner.apidev.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='default';name='apigw-stable-us.apidev.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'},
[pscustomobject]@{view='default';name='dev8.viper.xd2.blizzdmz.net'; canonical = 'haproxy-dtc.xd2.blizzdmz.net'}
)
$cnames | %{ New-IBObject -ObjectType 'record:cname' -IBObject $_ }


## Shared CNAMEs
$scr = [PSCustomObject]@{name='rfisher-test';canonical='ptr-removal-test-01.test.lab';shared_record_group='Blizzard Child Domains'}
New-IBObject -ObjectType 'sharedrecord:cname' -IBObject $scr


# Tracking Grid member changes
ipmo Posh-IBWAPI
Set-IBWAPIConfig -Credential Get-Credential -WAPIHost infoblox.blizzard.net -WAPIVersion latest
# Grid DNS settings
Get-IBObject -ObjectType grid:dns -ReturnAllFields | convertto-json
# Member DNS settings
Get-IBObject -ObjectType member:dns -ReturnAllFields | convertto-json



##############################
Get-IBObject -ObjectType zone_delegated -Filters 'fqdn=classic.blizzard.com' -ReturnAllFields  | convertto-json
@"
{
    "_ref":  "zone_delegated/ZG5zLnpvbmUkLl9kZWZhdWx0LmNvbS5ibGl6emFyZC5jbGFzc2lj:classic.blizzard.com/default",
    "comment":  "REQ000000397646",
    "delegate_to":  [
                        {
                            "address":  "205.251.195.212",
                            "name":  "ns-980.awsdns-58.net"
                        },
                        {
                            "address":  "205.251.199.196",
                            "name":  "ns-1988.awsdns-56.co.uk"
                        },
                        {
                            "address":  "205.251.196.41",
                            "name":  "ns-1065.awsdns-05.org"
                        },
                        {
                            "address":  "205.251.192.20",
                            "name":  "ns-20.awsdns-02.com"
                        }
                    ],
    "disable":  false,
    "display_domain":  "classic.blizzard.com",
    "dns_fqdn":  "classic.blizzard.com",
    "enable_rfc2317_exclusion":  false,
    "extattrs":  {

                 },
    "fqdn":  "classic.blizzard.com",
    "locked":  false,
    "ms_ad_integrated":  false,
    "ms_ddns_mode":  "NONE",
    "ms_managed":  "NONE",
    "ms_read_only":  false,
    "parent":  "blizzard.com",
    "use_delegated_ttl":  false,
    "using_srg_associations":  false,
    "view":  "default",
    "zone_format":  "FORWARD"
}
"@

# Request details:
# RITM00534812
# Jim Tario
# Please internally delegate forums.blizzard.com and to match public delegation for internal DNS resolution:
# Request For:	Jim Tario
# Title:	Associate Site Reliability Engineer
# Department:	IT - Site Reliability Engineering
# Email:	jtario@blizzard.com
# Location:	Irvine, B20
# Desk Location:	20-113
# Phone Number:	+1 949 9551380
# Watch List:	Ricardo Rosales, Tom Butkiewicz, Brandon Norbeck, Jonathan Eaton, James Barcellano, Callie Carrington
# ns-1587.awsdns-06.co.uk. 
# ns-441.awsdns-55.com. 
# ns-1144.awsdns-15.org. 
# ns-589.awsdns-09.net.

-split @"
ns-1587.awsdns-06.co.uk.
ns-441.awsdns-55.com.
ns-1144.awsdns-15.org.
ns-589.awsdns-09.net.
"@ | rdn -Type A | select @{l='address';e={$_.IPAddress}},@{l='name';e={$_.Name}} | convertto-json

$view = "default"
$fqdn = "forums.blizzard.com"
$parent = "blizzard.com"
$request = "RITM00534812"
$jsonNameServers = @"
[
    {
        "address":  "205.251.198.51",
        "name":  "ns-1587.awsdns-06.co.uk"
    },
    {
        "address":  "205.251.193.185",
        "name":  "ns-441.awsdns-55.com"
    },
    {
        "address":  "205.251.196.120",
        "name":  "ns-1144.awsdns-15.org"
    },
    {
        "address":  "205.251.194.77",
        "name":  "ns-589.awsdns-09.net"
    }
]
"@

$jsonZoneDelegation = @"
{
    "comment":  "$request",
    "delegate_to":  $jsonNameServers,
    "fqdn":  "$fqdn",
    "view":  "$view"
}
"@
$zdobject = $jsonZoneDelegation | ConvertFrom-Json
New-IBObject -ObjectType zone_delegated -IBObject $zdobject


#############################
# Move an host alias
@"
{
    "_ref":  "record:host/ZG5zLmhvc3QkLl9kZWZhdWx0Lm5ldC5ibGl6emFyZC5jb3JwLmlydmFwMTYw:irvap160.corp.blizzard.net/default",
    "aliases":  [
                    "wowloctool.corp.blizzard.net",
                    "wowdblogviewer.corp.blizzard.net",
                    "wowsearch.corp.blizzard.net",
                    "wowdatabaseviewer.corp.blizzard.net",
                    "wowdbreader.corp.blizzard.net",
                    "wowcommitmonitor.corp.blizzard.net",
                    "wowdamm.corp.blizzard.net",
                    "wowassetreports.corp.blizzard.net"
                ],
    "allow_telnet":  false,
    "comment":  "RITM00515923",
    "configure_for_dns":  true,
    "ddns_protected":  false,
    "disable":  false,
    "disable_discovery":  false,
    "dns_aliases":  [
                        "wowloctool.corp.blizzard.net",
                        "wowdblogviewer.corp.blizzard.net",
                        "wowsearch.corp.blizzard.net",
                        "wowdatabaseviewer.corp.blizzard.net",
                        "wowdbreader.corp.blizzard.net",
                        "wowcommitmonitor.corp.blizzard.net",
                        "wowdamm.corp.blizzard.net",
                        "wowassetreports.corp.blizzard.net"
                    ],
    "dns_name":  "irvap160.corp.blizzard.net",
    "extattrs":  {
                     "Site":  {
                                  "inheritance_source":  "@{_ref=networkcontainer/ZG5zLm5ldHdvcmtfY29udGFpbmVyJDEwLjEzMC4wLjAvMTcvMA:10.130.0.0/17/default}",
                                  "value":  "Irvine"
                              }
                 },
    "ipv4addrs":  [
                      {
                          "_ref":  "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuX2RlZmF1bHQubmV0LmJsaXp6YXJkLmNvcnAuaXJ2YXAxNjAuMTAuMTMwLjEuMjA3Lg:10.130.1.207/irvap160.corp.blizzar
d.net/default",
                          "configure_for_dhcp":  false,
                          "host":  "irvap160.corp.blizzard.net",
                          "ipv4addr":  "10.130.1.207"
                      }
                  ],
    "last_queried":  1516757269,
    "ms_ad_user_data":  {
                            "active_users_count":  0
                        },
    "name":  "irvap160.corp.blizzard.net",
    "network_view":  "default",
    "rrset_order":  "cyclic",
    "ttl":  1200,
    "use_cli_credentials":  false,
    "use_snmp3_credential":  false,
    "use_snmp_credential":  false,
    "use_ttl":  true,
    "view":  "default",
    "zone":  "corp.blizzard.net"
}

{
    "_ref":  "record:host/ZG5zLmhvc3QkLl9kZWZhdWx0Lm5ldC5ibGl6emFyZC5jb3JwLmlydmFwMTYw:irvap160.corp.blizzard.net/default",
    "aliases":  [
                    "wowloctool.corp.blizzard.net",
                    "wowdblogviewer.corp.blizzard.net",
                    "wowsearch.corp.blizzard.net",
                    "wowdatabaseviewer.corp.blizzard.net",
                    "wowdbreader.corp.blizzard.net",
                    "wowcommitmonitor.corp.blizzard.net",
                    "wowdamm.corp.blizzard.net",
                    "wowassetreports.corp.blizzard.net",
                    "wowtools.corp.blizzard.net"
                ],
    "allow_telnet":  false,
    "comment":  "RITM00515923",
    "configure_for_dns":  true,
    "ddns_protected":  false,
    "disable":  false,
    "disable_discovery":  false,
    "dns_aliases":  [
                        "wowloctool.corp.blizzard.net",
                        "wowdblogviewer.corp.blizzard.net",
                        "wowsearch.corp.blizzard.net",
                        "wowdatabaseviewer.corp.blizzard.net",
                        "wowdbreader.corp.blizzard.net",
                        "wowcommitmonitor.corp.blizzard.net",
                        "wowdamm.corp.blizzard.net",
                        "wowassetreports.corp.blizzard.net",
                        "wowtools.corp.blizzard.net"
                    ],
    "dns_name":  "irvap160.corp.blizzard.net",
    "extattrs":  {
                     "Site":  {
                                  "inheritance_source":  "@{_ref=networkcontainer/ZG5zLm5ldHdvcmtfY29udGFpbmVyJDEwLjEzMC4wLjAvMTcvMA:10.130.0.0/17/default}",
                                  "value":  "Irvine"
                              }
                 },
    "ipv4addrs":  [
                      {
                          "_ref":  "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuX2RlZmF1bHQubmV0LmJsaXp6YXJkLmNvcnAuaXJ2YXAxNjAuMTAuMTMwLjEuMjA3Lg:10.130.1.207/irvap160.corp.blizzard.net/default",
                          "configure_for_dhcp":  false,
                          "host":  "irvap160.corp.blizzard.net",
                          "ipv4addr":  "10.130.1.207"
                      }
                  ],
    "last_queried":  1516758318,
    "ms_ad_user_data":  {
                            "active_users_count":  0
                        },
    "name":  "irvap160.corp.blizzard.net",
    "network_view":  "default",
    "rrset_order":  "cyclic",
    "ttl":  1200,
    "use_cli_credentials":  false,
    "use_snmp3_credential":  false,
    "use_snmp_credential":  false,
    "use_ttl":  true,
    "view":  "default",
    "zone":  "corp.blizzard.net"
}
"@


############
# Update a member
Get-IBObject -ObjectType member:dns -ReturnFields forwarders | convertto-json
$ny = Get-IBObject -ObjectRef 'member:dns/ZG5zLm1lbWJlcl9kbnNfcHJvcGVydGllcyQyMQ:usbisl-nsi001.blizzard.net' -ReturnFields forwarders
$ny.forwarders = @('8.8.8.8','8.8.4.4')
$ny | Set-IBObject
Get-IBObject -ObjectRef 'member:dns/ZG5zLm1lbWJlcl9kbnNfcHJvcGVydGllcyQyMQ:usbisl-nsi001.blizzard.net' -ReturnFields forwarders



###########################
# Create SharedRecordGroup CNAMEs
Get-IBObject -ObjectType 'sharedrecord:cname' -Filters 'name=infoblox' -ReturnAllFields | convertto-json
@'
{
    "_ref":  "sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjIuaW5mb2Jsb3g:infoblox/Blizzard%20Child%20Domains",
    "canonical":  "infoblox.blizzard.net",
    "disable":  false,
    "dns_canonical":  "infoblox.blizzard.net",
    "dns_name":  "infoblox",
    "extattrs":  {

                 },
    "name":  "infoblox",
    "shared_record_group":  "Blizzard Child Domains",
    "use_ttl":  false
}
'@

<#
.SYNOPSIS
Creates shared cname records for the XD2 domains and views

.DESCRIPTION
Creates shared cname records for in the "XD@ Partner Services" shared record group. This ensures that these services are created in all the views and domains necessary to 

.EXAMPLE
An example

.NOTES
General notes
#>
function New-Xd2SharedCname {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string[]]$Name,
        [parameter(Mandatory=$True)]
        [string]$Canonical,
        [parameter(Mandatory=$True)]
        [string]$SharedRecordGroup,
        [string]$Comment
    )

    BEGIN {}
    PROCESS {
        foreach ($label in $Name) {
            $newCname = [pscustomobject]@{
                canonical = $Canonical
                name = $label
                shared_record_group = $SharedRecordGroup
                comment = $Comment
            }
            New-IBObject -ObjectType 'sharedrecord:cname' -IBObject $newCname
        }
    }
    END {}
}

$tuCNAME = -split @"
account-api-cn.web
account-api-eu.web
account-api-kr.web
account-api-kr.web
account-api-tw.web
account-api-us.web
bam-live-eu.web
bam-live-us.web
dev7-web-simple-checkout-assets.web
login-live-cn.web
login-live-eu.web
login-live-kr.web
login-live-tw.web
login-qa-cn.web
login-qa-eu.web
login-qa-kr.web
login-qa-tw.web
murky.web
nydus-qa.web
oauth-eu.web
oauth-us.web
partner.apidev
root-qa-eu.web
root-qa-us.web
shop-feature1-cn.web
shop-feature1-eu.web
shop-feature1-kr.web
shop-feature1-tw.web
shop-feature1-us.web
shop-live-eu.web
shop-live-us.web
shop-simple-checkout-cn.web
shop-simple-checkout-eu.web
shop-simple-checkout-kr.web
shop-simple-checkout-tw.web
shop-simple-checkout-us.web
"@
new-Xd2SharedCname -name $tuCNAME -canonical 'haproxy-dtc.xd2.blizzdmz.net' -SharedRecordGroup 'XD2 Partner Services' -comment 'RITM00534867 - required for Tassadar' -ErrorAction SilentlyContinue

$test = 'test1','test2','test3'
$test2 = 'test4','test5','test6'
$test | new-Xd2SharedCname -canonical 'haproxy-dtc.xd2.blizzdmz.net' -SharedRecordGroup 'XD2 Partner Services' -comment 'RITM00534867 - required for Tassadar'
new-Xd2SharedCname -name $test2 -canonical 'haproxy-dtc.xd2.blizzdmz.net' -SharedRecordGroup 'XD2 Partner Services' -comment 'RITM00534867 - required for Tassadar'

Get-IBObject -ObjectType allrecords -Filters 'zone=viper.xd2.blizzdmz.net' |? Name | sort name,view| ft -auto Name,view,zone
Get-IBObject -ObjectType allrecords -Filters 'view=dmz&zone=viper.xd2.blizzdmz.net' |? Name | sort name,view| ft -auto Name,view,zone

$refs = -split @"
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5hY2NvdW50LWFwaS1jbg:account-api-cn.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5hY2NvdW50LWFwaS1ldQ:account-api-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5hY2NvdW50LWFwaS1rcg:account-api-kr.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5hY2NvdW50LWFwaS10dw:account-api-tw.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5hY2NvdW50LWFwaS11cw:account-api-us.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5iYW0tbGl2ZS1ldQ:bam-live-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5iYW0tbGl2ZS11cw:bam-live-us.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5kZXY3LXdlYi1zaW1wbGUtY2hlY2tvdXQtYXNzZXRz:dev7-web-simple-checkout-assets.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5sb2dpbi1saXZlLWNu:login-live-cn.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5sb2dpbi1saXZlLWV1:login-live-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5sb2dpbi1saXZlLWty:login-live-kr.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5sb2dpbi1saXZlLXR3:login-live-tw.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5sb2dpbi1xYS1jbg:login-qa-cn.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5sb2dpbi1xYS1ldQ:login-qa-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5sb2dpbi1xYS1rcg:login-qa-kr.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5sb2dpbi1xYS10dw:login-qa-tw.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5tdXJreQ:murky.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5ueWR1cy1xYQ:nydus-qa.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5vYXV0aC1ldQ:oauth-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5yb290LXFhLWV1:root-qa-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5yb290LXFhLXVz:root-qa-us.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLWZlYXR1cmUxLWNu:shop-feature1-cn.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLWZlYXR1cmUxLWV1:shop-feature1-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLWZlYXR1cmUxLWty:shop-feature1-kr.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLWZlYXR1cmUxLXR3:shop-feature1-tw.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLWZlYXR1cmUxLXVz:shop-feature1-us.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLWxpdmUtZXU:shop-live-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC1jbg:shop-simple-checkout-cn.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC1ldQ:shop-simple-checkout-eu.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC1rcg:shop-simple-checkout-kr.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC10dw:shop-simple-checkout-tw.web/XD2%20Partner%20Services
sharedrecord:cname/ZG5zLmJpbmRfY25hbWUkLnNyZ19yb290LjExLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC11cw:shop-simple-checkout-us.web/XD2%20Partner%20Services
"@

function New-Xd2Cname {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string[]]$Name,
        [parameter(Mandatory=$True)]
        [string]$Canonical,
        [parameter(Mandatory=$True)]
        [validateset('default','dmz')]
        [string[]]$View = 'default',
        [string]$Comment
    )

    BEGIN {}
    PROCESS {
        foreach ($label in $Name) {
            foreach ($v in $View) {
                $newCname = [pscustomobject]@{
                    canonical = $Canonical
                    name = $label
                    comment = $Comment
                    view = $v
                }
                New-IBObject -ObjectType 'record:cname' -IBObject $newCname
            }
        }
    }
    END {}
}

$tassadar = -split @"
account-api-cn.web.blizzard.net
account-api-eu.web.blizzard.net
account-api-kr.web.blizzard.net
account-api-kr.web.blizzard.net
account-api-tw.web.blizzard.net
account-api-us.web.blizzard.net
apigw-stable-us.apidev.blizzard.net
bam-live-eu.web.blizzard.net
bam-live-us.web.blizzard.net
bungie-dedicated-us.web.blizzard.net
dev.depot.battle.net
dev8.bgs.battle.net
dev7-web-simple-checkout-assets.web.blizzard.net
login-live-cn.web.blizzard.net
login-live-eu.web.blizzard.net
login-live-kr.web.blizzard.net
login-live-tw.web.blizzard.net
login-live-us.web.blizzard.net
login-qa-cn.web.blizzard.net
login-qa-eu.web.blizzard.net
login-qa-kr.web.blizzard.net
login-qa-tw.web.blizzard.net
login-qa-us.web.blizzard.net
murky.web.blizzard.net
nydus-qa.web.blizzard.net
oauth-eu.web.blizzard.net
oauth-us.web.blizzard.net
partner.apidev.blizzard.net
public.apidev.blizzard.net
root-qa-eu.web.blizzard.net
root-qa-us.web.blizzard.net
shop-feature1-cn.web.blizzard.net
shop-feature1-eu.web.blizzard.net
shop-feature1-kr.web.blizzard.net
shop-feature1-tw.web.blizzard.net
shop-feature1-us.web.blizzard.net
shop-live-eu.web.blizzard.net
shop-live-us.web.blizzard.net
shop-simple-checkout-cn.web.blizzard.net
shop-simple-checkout-eu.web.blizzard.net
shop-simple-checkout-kr.web.blizzard.net
shop-simple-checkout-tw.web.blizzard.net
shop-simple-checkout-us.web.blizzard.net
"@ -match '\.web\.blizzard\.net$'
new-xd2cname -Name $tassadar -Canonical 'haproxy-dtc.xd2.blizzdmz.net' -View 'dmz' -comment 'RITM00534867 - required for Tassadar' -erroraction SilentlyContinue


$refs = -split @"
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5hY2NvdW50LWFwaS1jbg:account-api-cn.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5hY2NvdW50LWFwaS1ldQ:account-api-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5hY2NvdW50LWFwaS1rcg:account-api-kr.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5hY2NvdW50LWFwaS10dw:account-api-tw.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5hY2NvdW50LWFwaS11cw:account-api-us.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5iYW0tbGl2ZS1ldQ:bam-live-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5iYW0tbGl2ZS11cw:bam-live-us.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5idW5naWUtZGVkaWNhdGVkLXVz:bungie-dedicated-us.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5kZXY3LXdlYi1zaW1wbGUtY2hlY2tvdXQtYXNzZXRz:dev7-web-simple-checkout-assets.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5sb2dpbi1saXZlLWNu:login-live-cn.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5sb2dpbi1saXZlLWV1:login-live-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5sb2dpbi1saXZlLWty:login-live-kr.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5sb2dpbi1saXZlLXR3:login-live-tw.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5sb2dpbi1xYS1jbg:login-qa-cn.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5sb2dpbi1xYS1ldQ:login-qa-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5sb2dpbi1xYS1rcg:login-qa-kr.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5sb2dpbi1xYS10dw:login-qa-tw.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5tdXJreQ:murky.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5ueWR1cy1xYQ:nydus-qa.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5vYXV0aC1ldQ:oauth-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5vYXV0aC11cw:oauth-us.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5yb290LXFhLWV1:root-qa-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5yb290LXFhLXVz:root-qa-us.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLWZlYXR1cmUxLWNu:shop-feature1-cn.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLWZlYXR1cmUxLWV1:shop-feature1-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLWZlYXR1cmUxLWty:shop-feature1-kr.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLWZlYXR1cmUxLXR3:shop-feature1-tw.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLWZlYXR1cmUxLXVz:shop-feature1-us.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLWxpdmUtZXU:shop-live-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLWxpdmUtdXM:shop-live-us.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC1jbg:shop-simple-checkout-cn.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC1ldQ:shop-simple-checkout-eu.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC1rcg:shop-simple-checkout-kr.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC10dw:shop-simple-checkout-tw.web.blizzard.net/dmz
record:cname/ZG5zLmJpbmRfY25hbWUkLjIubmV0LmJsaXp6YXJkLndlYi5zaG9wLXNpbXBsZS1jaGVja291dC11cw:shop-simple-checkout-us.web.blizzard.net/dmz
"@

##################################################################

function New-Xd2Cname {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string]$Name,
        
        [parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
        [string]$Canonical,
        
        [parameter(Mandatory=$True)]
        [validateset('default','dmz')]
        [string[]]$View = 'default',
        
        [string]$Comment
    )

    BEGIN {}
    PROCESS {
        foreach ($v in $View) {
            $newCname = [pscustomobject]@{
                canonical = $Canonical
                name = $Name
                comment = $Comment
                view = $v
            }
            New-IBObject -ObjectType 'record:cname' -IBObject $newCname
        }
    }
    END {}
}

$cname = @"
artemis.cn.blizzard.com                        CNAME ----> farsight-artemis-master.cn-north-1.eb.amazonaws.com.cn  
artemis-release.cn.blizzard.com                CNAME ----> farsight-artemis-release.cn-north-1.eb.amazonaws.com.cn 
farsight.cn.blizzard.com                       CNAME ----> farsight-calendar-master.cn-north-1.eb.amazonaws.com.cn 
farsight-release.cn.blizzard.com               CNAME ----> farsight-calendar-release.cn-north-1.eb.amazonaws.com.cn
communitytournaments.cn.blizzard.com           CNAME ----> farsight-license-master.cn-north-1.eb.amazonaws.com.cn  
communitytournaments-release.cn.blizzard.com   CNAME ----> farsight-license-release.cn-north-1.eb.amazonaws.com.cn
"@ -split "`n"
$cname |%{
    $name,$canonical = $_ -split '\s+CNAME ----> '
    [pscustomobject]@{
        Name = $Name.trim()
        Canonical = $canonical.trim()
    }
} | new-xd2cname -View default -comment 'RITM00535072'


record:cname/ZG5zLmJpbmRfY25hbWUkLl9kZWZhdWx0LmNvbS5ibGl6emFyZC5jbi5hcnRlbWlz:artemis.cn.blizzard.com/default
record:cname/ZG5zLmJpbmRfY25hbWUkLl9kZWZhdWx0LmNvbS5ibGl6emFyZC5jbi5hcnRlbWlzLXJlbGVhc2U:artemis-release.cn.blizzard.com/default
record:cname/ZG5zLmJpbmRfY25hbWUkLl9kZWZhdWx0LmNvbS5ibGl6emFyZC5jbi5mYXJzaWdodA:farsight.cn.blizzard.com/default
record:cname/ZG5zLmJpbmRfY25hbWUkLl9kZWZhdWx0LmNvbS5ibGl6emFyZC5jbi5mYXJzaWdodC1yZWxlYXNl:farsight-release.cn.blizzard.com/default
record:cname/ZG5zLmJpbmRfY25hbWUkLl9kZWZhdWx0LmNvbS5ibGl6emFyZC5jbi5jb21tdW5pdHl0b3VybmFtZW50cw:communitytournaments.cn.blizzard.com/default
record:cname/ZG5zLmJpbmRfY25hbWUkLl9kZWZhdWx0LmNvbS5ibGl6emFyZC5jbi5jb21tdW5pdHl0b3VybmFtZW50cy1yZWxlYXNl:communitytournaments-release.cn.blizzard.com/default

###########################################################
# RITM00536289 Exadata records.
###########################################################
$rhosts = @"
Hostname,IPAddress,Comment
oc2-exa1-dbadm01.corp.blizzard.net,10.133.145.10,Exadata Admin
oc2-exa1-dbadm02.corp.blizzard.net,10.133.145.11,Exadata Admin
oc2-exa1-dbadm03.corp.blizzard.net,10.133.145.12,Exadata Admin
oc2-exa1-dbadm04.corp.blizzard.net,10.133.145.13,Exadata Admin
oc2-exa1-dbadm05.corp.blizzard.net,10.133.145.14,Exadata Admin
oc2-exa1-dbadm06.corp.blizzard.net,10.133.145.15,Exadata Admin
oc2-exa1-celadm01.corp.blizzard.net,10.133.145.16,Exadata Admin
oc2-exa1-celadm02.corp.blizzard.net,10.133.145.17,Exadata Admin
oc2-exa1-celadm03.corp.blizzard.net,10.133.145.18,Exadata Admin
oc2-exa1-celadm04.corp.blizzard.net,10.133.145.19,Exadata Admin
oc2-exa1-celadm05.corp.blizzard.net,10.133.145.20,Exadata Admin
oc2-exa1-celadm06.corp.blizzard.net,10.133.145.21,Exadata Admin
oc2-exa1-celadm07.corp.blizzard.net,10.133.145.22,Exadata Admin
oc2-exa1-sw-adm01.corp.blizzard.net,10.133.145.36,Exadata Admin
oc2-exa1-sw-iba01.corp.blizzard.net,10.133.145.37,Exadata Admin
oc2-exa1-sw-ibb01.corp.blizzard.net,10.133.145.38,Exadata Admin
oc2-exa1-sw-pdua01.corp.blizzard.net,10.133.145.39,Exadata Admin
oc2-exa1-sw-pdub01.corp.blizzard.net,10.133.145.40,Exadata Admin
oc2-exa1-dbadm01-ilom.corp.blizzard.net,10.133.145.23,Exadata ILOM
oc2-exa1-dbadm02-ilom.corp.blizzard.net,10.133.145.24,Exadata ILOM
oc2-exa1-dbadm03-ilom.corp.blizzard.net,10.133.145.25,Exadata ILOM
oc2-exa1-dbadm04-ilom.corp.blizzard.net,10.133.145.26,Exadata ILOM
oc2-exa1-dbadm05-ilom.corp.blizzard.net,10.133.145.27,Exadata ILOM
oc2-exa1-dbadm06-ilom.corp.blizzard.net,10.133.145.28,Exadata ILOM
oc2-exa1-celadm01-ilom.corp.blizzard.net,10.133.145.29,Exadata ILOM
oc2-exa1-celadm02-ilom.corp.blizzard.net,10.133.145.30,Exadata ILOM
oc2-exa1-celadm03-ilom.corp.blizzard.net,10.133.145.31,Exadata ILOM
oc2-exa1-celadm04-ilom.corp.blizzard.net,10.133.145.32,Exadata ILOM
oc2-exa1-celadm05-ilom.corp.blizzard.net,10.133.145.33,Exadata ILOM
oc2-exa1-celadm06-ilom.corp.blizzard.net,10.133.145.34,Exadata ILOM
oc2-exa1-celadm07-ilom.corp.blizzard.net,10.133.145.35,Exadata ILOM
oc2-exa1-db01.corp.blizzard.net,10.133.144.10,Exadata Client
oc2-exa1-db02.corp.blizzard.net,10.133.144.12,Exadata Client
oc2-exa1-db03.corp.blizzard.net,10.133.144.14,Exadata Client
oc2-exa1-db04.corp.blizzard.net,10.133.144.16,Exadata Client
oc2-exa1-db05.corp.blizzard.net,10.133.144.18,Exadata Client
oc2-exa1-db06.corp.blizzard.net,10.133.144.20,Exadata Client
oc2-exa1-db01-vip.corp.blizzard.net,10.133.144.11,Exadata VIP
oc2-exa1-db02-vip.corp.blizzard.net,10.133.144.13,Exadata VIP
oc2-exa1-db03-vip.corp.blizzard.net,10.133.144.15,Exadata VIP
oc2-exa1-db04-vip.corp.blizzard.net,10.133.144.17,Exadata VIP
oc2-exa1-db05-vip.corp.blizzard.net,10.133.144.19,Exadata VIP
oc2-exa1-db06-vip.corp.blizzard.net,10.133.144.21,Exadata VIP
oc2-exa1-db01-priv1.corp.blizzard.net,192.168.60.10,Exadata Private
oc2-exa1-db01-priv2.corp.blizzard.net,192.168.60.11,Exadata Private
oc2-exa1-db02-priv1.corp.blizzard.net,192.168.60.12,Exadata Private
oc2-exa1-db02-priv2.corp.blizzard.net,192.168.60.13,Exadata Private
oc2-exa1-db03-priv1.corp.blizzard.net,192.168.60.14,Exadata Private
oc2-exa1-db03-priv2.corp.blizzard.net,192.168.60.15,Exadata Private
oc2-exa1-db04-priv1.corp.blizzard.net,192.168.60.16,Exadata Private
oc2-exa1-db04-priv2.corp.blizzard.net,192.168.60.17,Exadata Private
oc2-exa1-db05-priv1.corp.blizzard.net,192.168.60.18,Exadata Private
oc2-exa1-db05-priv2.corp.blizzard.net,192.168.60.19,Exadata Private
oc2-exa1-db06-priv1.corp.blizzard.net,192.168.60.20,Exadata Private
oc2-exa1-db06-priv2.corp.blizzard.net,192.168.60.21,Exadata Private
oc2-exa1-cel01-priv1.corp.blizzard.net,192.168.60.22,Exadata Private
oc2-exa1-cel01-priv2.corp.blizzard.net,192.168.60.23,Exadata Private
oc2-exa1-cel02-priv1.corp.blizzard.net,192.168.60.24,Exadata Private
oc2-exa1-cel02-priv2.corp.blizzard.net,192.168.60.25,Exadata Private
oc2-exa1-cel03-priv1.corp.blizzard.net,192.168.60.26,Exadata Private
oc2-exa1-cel03-priv2.corp.blizzard.net,192.168.60.27,Exadata Private
oc2-exa1-cel04-priv1.corp.blizzard.net,192.168.60.28,Exadata Private
oc2-exa1-cel04-priv2.corp.blizzard.net,192.168.60.29,Exadata Private
oc2-exa1-cel05-priv1.corp.blizzard.net,192.168.60.30,Exadata Private
oc2-exa1-cel05-priv2.corp.blizzard.net,192.168.60.31,Exadata Private
oc2-exa1-cel06-priv1.corp.blizzard.net,192.168.60.32,Exadata Private
oc2-exa1-cel06-priv2.corp.blizzard.net,192.168.60.33,Exadata Private
oc2-exa1-cel07-priv1.corp.blizzard.net,192.168.60.34,Exadata Private
oc2-exa1-cel07-priv2.corp.blizzard.net,192.168.60.35,Exadata Private
oc2-exa1-db01-bu.corp.blizzard.net,10.133.146.10,Exadata Backup
oc2-exa1-db02-bu.corp.blizzard.net,10.133.146.11,Exadata Backup
oc2-exa1-db03-bu.corp.blizzard.net,10.133.146.12,Exadata Backup
oc2-exa1-db04-bu.corp.blizzard.net,10.133.146.13,Exadata Backup
oc2-exa1-db05-bu.corp.blizzard.net,10.133.146.14,Exadata Backup
oc2-exa1-db06-bu.corp.blizzard.net,10.133.146.15,Exadata Backup
"@ -split "`n" | ConvertFrom-Csv

$newhosts = $rhosts.foreach(
    {
        $object = [pscustomobject]@{
            name = $_.Hostname
            ipv4addrs = @([pscustomobject]@{ipv4addr = $_.IPAddress})
            comment = 'RITM00536289 ' + $_.comment
            ddns_protected = $True
            device_type = 'Exadata Appliance'
            device_vendor = 'Oracle'
            device_description = 'exadata'
            enable_immediate_discovery = $False
        }
        New-IBObject -ObjectType 'record:host' -IBObject $object
    }
    )
    
@"
Exadata Client SCAN IP
oc2-exa1-scan.corp.blizzard.net,10.133.144.22
oc2-exa1-scan.corp.blizzard.net,10.133.144.23
oc2-exa1-scan.corp.blizzard.net,10.133.144.24
"@

$object = [pscustomobject]@{
    name = "oc2-exa1-scan.corp.blizzard.net"
    ipv4addrs = @(
        [pscustomobject]@{ipv4addr = "10.133.144.22"}
        [pscustomobject]@{ipv4addr = "10.133.144.23"}
        [pscustomobject]@{ipv4addr = "10.133.144.24"}
    )
    comment = 'RITM00536289 ' + 'Exadata Client SCAN IP'
    ddns_protected = $True
    device_type = 'Exadata Appliance'
    device_vendor = 'Oracle'
    device_description = 'exadata'
    enable_immediate_discovery = $False
}
New-IBObject -ObjectType 'record:host' -IBObject $object


<#
.SYNOPSIS
Searches for records using the allrecords object.

.DESCRIPTION
Long description

.EXAMPLE
An example

.NOTES
General notes
#>
function Search-IBObject {
    param (
        
    )
}

#################################################
$hosts = @"
hostname,ipaddress
oc2-exa1-sw-adm01.corp.blizzard.net,10.133.145.28
oc2-exa1-sw-iba01.corp.blizzard.net,10.133.145.29
oc2-exa1-sw-ibb01.corp.blizzard.net,10.133.145.30
oc2-exa1-sw-pdua01.corp.blizzard.net,10.133.145.31
oc2-exa1-sw-pdub01.corp.blizzard.net,10.133.145.32
oc2-exa1-dbadm01-ilom.corp.blizzard.net,10.133.145.19
oc2-exa1-dbadm02-ilom.corp.blizzard.net,10.133.145.20
oc2-exa1-dbadm03-ilom.corp.blizzard.net,10.133.145.21
oc2-exa1-dbadm04-ilom.corp.blizzard.net,10.133.145.22
oc2-exa1-dbadm05-ilom.corp.blizzard.net,10.133.145.23
oc2-exa1-dbadm06-ilom.corp.blizzard.net,10.133.145.24
oc2-exa1-celadm01-ilom.corp.blizzard.net,10.133.145.25
oc2-exa1-celadm02-ilom.corp.blizzard.net,10.133.145.26
oc2-exa1-celadm03-ilom.corp.blizzard.net,10.133.145.27
"@ -split "`n" | convertfrom-csv

$hosts.hostname | %{ get-ibobject -ObjectType record:host -filter "name=$_" }

foreach ($rec in $hosts) {
    $ref = get-ibobject -ObjectType record:host -filter "name=$($rec.hostname)" | select _ref,ipv4addrs
    $ref.ipv4addrs = @([pscustomobject]@{ipv4addr = $rec.IPAddress})
    set-ibobject -ibobject $ref
}

#####################################################
# Networks 
$network_nodhcp_noddns = @"
_ref                                 : network/ZG5zLm5ldHdvcmskMTAuNDcuMC4wLzE2LzA:10.47.0.0/16/default
comment                              : BONS
disable                              : True
discover_now_status                  : NONE
email_list                           : {}
enable_ddns                          : False
enable_discovery                     : False
extattrs                             : @{Site=; Status=}
ipv4addr                             : 10.47.0.0
netmask                              : 16
network                              : 10.47.0.0/16
network_container                    : 10.0.0.0/9
network_view                         : default
"@

$network_nodhcp_noddns = [pscustomobject](@"
comment = BONS
disable = True
discover_now_status = NONE
email_list = {}
enable_ddns = False
enable_discovery = False
extattrs = @{Site=; Status=}
ipv4addr = 10.47.0.0
netmask = 16
network = 10.47.0.0/16
network_container = 10.0.0.0/9
network_view = default
"@ | ConvertFrom-StringData
)

function New-NetworkStatic {
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string]$Network,
        [parameter(ValueFromPipelineByPropertyName=$True)]
        [string]$Comment = "created by New-NetworkStatic $(get-date)",
        [parameter(ValueFromPipelineByPropertyName=$True)]
        [string]$Site
    )
    begin {}
    process {
        [pscustomobject]$objNetwork = @{
            network = $network
            comment = $Comment
            enable_discovery = $False
            enable_ddns = $False
            disable = $True
            extattrs = @{
                Site = @{value=$site}
                Status = @{value='keep'}
            }
        }
        try {
            new-ibobject -ObjectType 'network' -ibobject $objNetwork
        }
        catch {
            switch -regex ($_.FullyQualifiedErrorId) {
                'overlap an existing network' { 
                    $objNetworkContainer = $objNetwork | select * -ExcludeProperty Disable
                    new-ibobject -ObjectType 'networkcontainer' -ibobject $objNetwork
                    break
                }
                'already exists' { Write-Warning "$Network already exists"; break}
                Default {throw $_}
            }
        }
    }
    end {}
}


@"
site,network,comment
lax1,10.104.0.0/16,BONS
ord1,10.108.0.0/16,BONS
las1,10.114.0.0/16,BONS
ams1,10.105.0.0/16,BONS
cdg1,10.109.0.0/16,BONS
pa3,10.51.0.0/16,BONS
"@ -split "`n" | convertfrom-csv | New-NetworkStatic

$sechosts = @"
hostname,ipaddress,comment
lax1-sec-pafw01.ids.blizzard.net,10.104.197.7,Palo Alto Firewall
ord1-sec-pafw01.ids.blizzard.net,10.108.215.68,Palo Alto Firewall
las1-sec-pafw01.ids.blizzard.net,10.114.206.16,Palo Alto Firewall
ams1-sec-pafw01.ids.blizzard.net,10.105.215.68,Palo Alto Firewall
cdg1-sec-pafw01.ids.blizzard.net,10.109.215.68,Palo Alto Firewall
pa3-sec-pafw01.ids.blizzard.net,10.51.0.10,Palo Alto Firewall
"@ -split "`n" | ConvertFrom-Csv

$newhosts = $sechosts.foreach(
    {
        $object = [pscustomobject]@{
            name = $_.Hostname
            ipv4addrs = @([pscustomobject]@{ipv4addr = $_.IPAddress})
            comment = 'RITM00536567 ' + $_.comment
            ddns_protected = $True
            device_type = 'Firewall Appliance'
            device_vendor = 'Palo Alto'
            device_description = 'Palo Alto Firewall'
            enable_immediate_discovery = $False
        }
        New-IBObject -ObjectType 'record:host' -IBObject $object
    }
)

<#
_ref
----
namedacl/b25lLmRlZmluZWRfYWNsJDAuYWxsb3cgcHJvamVjdCB2aXBlcg:allow%20project%20viper
#>
$aclViewDmz = Get-IBObject -ObjectType namedacl -ReturnAllFields -Filters 'name=view dmz'
#$aclProjectViper = $aclViewDmz.access_list | Get-IBObject -ObjectType namedacl -ReturnAllFields
foreach ($item in $aclViewDmz.access_list) {
    if ($item._struct -eq 'addressac') {
        $item._struct
        $item.address
        $item.permission
    }
    elseif ($item._struct -eq 'tsigac') {
        $item
    }
    elseif ($item._ref -match '^namedacl') {
        $item
    }
    else {throw 'Unknown '}
}


##################################
# Whitelisting ACL items in a namedacl



######################################
# Delegate a zone to ATT internally
@"
{
    "_ref":  "zone_delegated/ZG5zLnpvbmUkLl9kZWZhdWx0LmNvbS5ibGl6emFyZC5hY2NvdW50:account.blizzard.com/default",
    "delegate_to":  [
                        {
                            "address":  "99.99.99.136",
                            "name":  "ns-east.cerf.net"
                        },
                        {
                            "address":  "68.94.156.136",
                            "name":  "ns-west.cerf.net"
                        }
                    ],
    "fqdn":  "account.blizzard.com",
    "view":  "default"
}
"@

$zoneDelg = [pscustomobject]@{
    comment = 'RITM00537484'
    fqdn = 'integration.blizzard.com'
    delegate_to = @(
        [pscustomobject]@{name = 'ns-east.cerf.net';address='99.99.99.136'},
        [pscustomobject]@{name = 'ns-west.cerf.net';address='68.94.156.136'}
    )
}



$dc1 = 'somedc.domain.local'
$dmzNS = '10.131.14.205'
$zones = -split @"
blizzdmz.net
dev8.bgs.battle.net
dev.depot.battle.net
apidev.blizzard.net
web.blizzard.net
"@
foreach ($zone in $zones ) {
    Add-DnsServerConditionalForwarderZone -ComputerName $dc1 -MasterServers $dmzNS -ReplicationScope Domain -Name $zone
}

###########################
# Add the Infoblox members from Activision to the DMZ

$members = -split @"
10.10.65.100
10.17.65.100
10.28.65.100
10.38.40.50
10.38.65.100
10.40.65.100
10.61.65.100
10.62.40.50
10.62.65.100
10.100.65.100
10.110.65.100
10.113.65.100
10.114.2.249
10.122.40.50
10.122.65.100
10.129.207.231
10.141.2.210
10.150.5.100
10.160.13.51
10.161.65.100
10.162.2.10
10.163.65.100
10.164.65.100
10.171.65.100
10.192.65.100
10.192.65.110
10.192.65.120
10.192.230.50
10.216.65.100
10.220.40.50
10.220.65.100
10.222.2.25
10.223.65.100
10.224.65.100
10.225.65.100
10.227.65.100
10.231.65.100
10.233.65.100
10.234.40.50
10.234.65.100
10.235.40.50
10.235.65.100
10.236.65.100
10.237.65.100
10.240.40.50
10.240.65.100
"@

$members.foreach(
    {[pscustomobject]@{_struct='addressac';permission='ALLOW';address="$_"}}
)
Get-IBObject -ObjectType namedacl -ReturnFields access_list -Filters 'name=allow address activision' |
    %{ $_.access_list = $atviIP; $_ } |
    Set-IBObject


##########################################
# Create a named acl for an project

function Add-ProjectACL {
    param (
        [string]$Project,
        [string]$Studio,
        [string]$Forwarder,
        [string[]]$Subnet
    )

}
##############################################

$ForwardTo = @(
    @{
        name = 'se1-bons-corpdns-vip01.battle.net'
        address = '10.47.34.216'
    },
    @{
        name = 'se1-bons-corpdns-vip02.battle.net'
        address = '10.47.34.217'
    }
)

###############################################
# Get rid of the dmz/web.blizzard.net zone, and move stuff into dmz/blizzard.net
$old = Get-IBObject -ObjectType record:cname -Filters 'view=dmz&name~=web.blizzard.net' -ReturnFields canonical,comment
$zone = Get-IBObject -ObjectType zone_auth -Filters 'view=dmz&fqdn=web.blizzard.net' -ReturnFields fqdn,comment
$zone | Remove-IBObject
$old | Select Name,Canonical,comment | New-IBObject -ObjectType record:cname


##################################
# Get zones that match a forwarder string.
Get-IBObject -ObjectType zone_forward | ?{$_.forward_to.name -match 'activision.com'} |% fqdn

#######################
# Get DNS members, test external resolution
# 
$dns = Get-IBObject -ObjectType member:dns -ReturnFields host_name,ipv4addr,forwarders,additional_ip_list,enable_dns |? enable_dns -eq $True
$dns  |% { $h = $_.host_name; Resolve-DnsName -Server $_.ipv4addr -Name outlook.office365.com -Type A| select -Last 1 -Property @{n='host';e={$h}},Name  }


################################
# Change DHCP
@"
[
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjAuMC8yNS8w:10.136.0.0/25/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.136.8.10; ipv6addr=; name=usbisl-nsd001.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.136.8.10; ipv6addr=; name=usbisl-nsd001.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjcuMC8yNC8w:10.136.7.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjYuMTI4LzI1LzA:10.136.6.128/25/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjMuMC8yNi8w:10.136.3.0/26/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjYuMC8yNS8w:10.136.6.0/25/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjE2LjAvMjMvMA:10.136.16.0/23/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjIwLjAvMjIvMA:10.136.20.0/22/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjI0LjAvMjQvMA:10.136.24.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjI2LjAvMjQvMA:10.136.26.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjI4LjAvMjQvMA:10.136.28.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjQ0LjAvMjMvMA:10.136.44.0/23/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjQ4LjAvMjQvMA:10.136.48.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjQ5LjAvMjQvMA:10.136.49.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjUwLjAvMjQvMA:10.136.50.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjU0LjAvMjQvMA:10.136.54.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjU2LjAvMjIvMA:10.136.56.0/22/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjYwLjAvMjIvMA:10.136.60.0/22/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjEwLjAvMjQvMA:10.136.10.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjMwLjAvMjQvMA:10.136.30.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM0LjQuMC8yNC8w:10.134.4.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    },
    {
        "_ref":  "network/ZG5zLm5ldHdvcmskMTAuMTM2LjMyLjAvMjQvMA:10.136.32.0/24/default",
        "members":  [
                        "@{_struct=dhcpmember; ipv4addr=10.131.62.176; ipv6addr=; name=cdc-utl-107.blizzard.net}",
                        "@{_struct=dhcpmember; ipv4addr=10.131.130.26; ipv6addr=; name=aus-utl-100.blizzard.net}"
                    ]
    }
]
"@



$ns = @"
av-infoblox820.activision.com
abstudios-infoblox825-a.activision.com
its-infoblox820-a.activision.com
ukic1-infoblox820-dmz.activision.com
ukic1-infoblox1410.activision.com
euic2-infoblox820-a.activision.com
pyrmont-infoblox810-a.activision.com
auic1-infoblox810-dmz-a.activision.com
auic1-infoblox810-a.activision.com
raven-infoblox820-a.activision.com
eden7800-infoblox820-a.activision.com
bloomington-infoblox820-a.activision.com
vv-infoblox820-a.activision.com
usic7-infoblox820-dmz.activision.com
usic7-infoblox820-a.activision.com
highmoon-infoblox820-a.activision.com
tfb-infoblox820.activision.com
ta-infoblox820-a.activision.com
iw-infoblox820-a.activision.com
iwmocap-infoblox810-a.activision.com
mocap-infoblox810-a.activision.com
shermanoaks-infoblox825-a.activision.com
esqa-infoblox820-a.activision.com
beenox-infoblox820-a.activision.com
usic2-infoblox820-a.activision.com
usic2-infoblox1410-axfr.activision.com
usic2-infoblox2220-gm.activision.com
usic2-infoblox1410-dmz.activision.com
amsterdam-infoblox825-a.activision.com
usic3-infoblox1410-dmz.activision.com
usic3-infoblox1410.activision.com
sledgehammer-infoblox820-a.activision.com
fresno1-infoblox810-a.activision.com
spain-infoblox810-a.activision.com
fresno-infoblox820-a.activision.com
usic5-infoblox820-a.activision.com
shanghai-infoblox825-vm.activision.com
italy-infoblox820-a.activision.com
cnic2-infoblox820-dmz.activision.com
cnic2-infoblox820.activision.com
cnic1-infoblox820-dmz.activision.com
cnic1-infoblox825-vm.activision.com
ditton-infoblox820-a.activision.com
venlo-infoblox810-a.activision.com
usic4-infoblox820-dmz.activision.com
usic4-infoblox820.activision.com
"@ -split "`n"

$rxFail = '*** Request to av-infoblox820.activision.com timed-out'
$rxpass = 'Name:    usbisl-prox002-tcp.xd2.blizzdmz.net'

$ns | %{ nslookup dev8.bgs.battle.net }
