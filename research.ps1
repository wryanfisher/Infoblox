# Notes working with the GUI, ideas to update etc.

# Create an authenticated session and stores it in the named Variable
$baseURI = 'https://infoblox.blizzard.net/wapi/v2.3.1'
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
