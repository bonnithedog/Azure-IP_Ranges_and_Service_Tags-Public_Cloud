# Function to download and process the JSON file
function Get-AzureIPs {
    # URL of the JSON file
    $url = "https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20240715.json"
        
    # Download the JSON file content
    try {
        $jsonContent = Invoke-RestMethod -Uri $url -Method Get
    } catch {
        Write-Output "Failed to download the JSON file."
        return
    }
    
    return $jsonContent
}

# Function to create allow rules for each IP range if not already present
function Add-AllowRule {
    param (
        [string]$ipRange,
        [string]$groupName,
        [string]$displayName
    )
    $existingRuleOutbound = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "$displayName $ipRange" -and $_.Direction -eq "Outbound" }
    $existingRuleInbound = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "$displayName $ipRange" -and $_.Direction -eq "Inbound" }
    
    if (-not $existingRuleOutbound) {
        New-NetFirewallRule -DisplayName "$displayName $ipRange" -Direction Outbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol TCP -Group $groupName | Out-Null
    }
    if (-not $existingRuleInbound) {
        New-NetFirewallRule -DisplayName "$displayName $ipRange" -Direction Inbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol TCP -Group $groupName | Out-Null
    }
}

# Function to write each service section's IP addresses to a separate file
function Write-ServiceSections {
    param (
        [Parameter(Mandatory = $true)]
        [Object]$Data
    )


    foreach ($service in $Data.values) {
        $serviceName = $service.name
        #Write-Output "Writing Service: $serviceName"
        # Extract the IP addresses
        $ipAddresses = $service.properties.addressPrefixes
        $resolvedIPs = Resolve-DNS -dnsName $dns
        foreach ($ip in $ipAddresses) {
            #Write-Output "Allowing traffic to $ip (read from $serviceName)"
            Add-AllowRule -ipRange $ip -groupName $serviceName -displayName "Allow $serviceName"
        }
    }



    }


# Main- function to execute the process
function ServiceTags_Public {
    $jsonData = Get-AzureIPs
    if ($null -eq $jsonData) {
        Write-Output "No data to process."
        return
    }

    Write-ServiceSections -Data $jsonData
}

# Run the main function
ServiceTags_Public
