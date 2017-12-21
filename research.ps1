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
$cred = Get-Credential
$ip = '10.254.254.70'
$rname = 'ptr-removal-test-03.test.lab'
Set-IBWAPIConfig -WAPIHost $grid -WAPIVersion 'latest' -Credential $cred

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

