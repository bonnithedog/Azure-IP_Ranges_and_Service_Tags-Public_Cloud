### If you want to automate the solution to fetch latest file. You can use this function.
##function Get-AzureIPs {
 #   # URL of the download page
 #   $downloadPageUrl = "https://www.microsoft.com/en-us/download/details.aspx?id=56519&msockid=088347aa29b462b33e10533928e36384"
 #   
 #   # Download the webpage content
 #   try {
 #       $webpageContent = Invoke-WebRequest -Uri $downloadPageUrl -Method Get -ErrorAction Stop
 #   } catch {
 #       Write-Output "Failed to download the webpage content: $_"
 #       return
 #   }
 #
 #   # Parse the HTML to find the download link
 #   try {
 #       $downloadLink = $webpageContent.Links | Where-Object { $_.href -match "download.microsoft.com" } | Select-Object -First 1 -ExpandProperty href
 #   } catch {
 #       Write-Output "Failed to parse the HTML or find the download link."
 #       return
 #   }
 #
 #   if (-not $downloadLink) {
 #       Write-Output "Failed to locate the download link."
 #       return
 #   }
 #
 #   # Download the latest JSON file content
 #   try {
 #       $jsonContent = Invoke-RestMethod -Uri $downloadLink -Method Get -ErrorAction Stop
 #   } catch {
 #       Write-Output "Failed to download the JSON file: $_"
 #       return
 #   }
 #
 #   # Convert JSON content to string and get the first 20 lines
 #   $jsonContent | ConvertTo-Json -Depth 10 | Select-String -Pattern "^" | Select-Object -First 20
 #}
##
# Call the function Get-AzureIPs
#Get-AzureIPs

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
        New-NetFirewallRule -DisplayName "$ipRange TCP $displayName" -Direction Outbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol TCP -Group $groupName | Out-Null
        New-NetFirewallRule -DisplayName "$ipRange UDP $displayName" -Direction Outbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol UDP -Group $groupName | Out-Null
    }
    if (-not $existingRuleInbound) {
        New-NetFirewallRule -DisplayName "$ipRange TCP $displayName" -Direction Inbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol TCP -Group $groupName | Out-Null
        New-NetFirewallRule -DisplayName "UDP $displayName $ipRange" -Direction Inbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol UDP -Group $groupName | Out-Null
    }
}




# Function to resolve DNS names to IP addresses
function Resolve-DNS {
    param (
        [string]$dnsName
    )
    try {
        [System.Net.Dns]::GetHostAddresses($dnsName) | ForEach-Object { $_.IPAddressToString }
    } catch {
        Write-Error "Failed to resolve DNS name: $dnsName"
        return @()
    }
}











# Function to write each service section's IP addresses to a rule
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
