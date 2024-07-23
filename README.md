## Azure IPs Firewall Rules Automation

# Overview
This PowerShell script automates the process of downloading, processing, and configuring Windows Firewall rules based on Azure service tags. The script retrieves a JSON file containing the latest Azure IP ranges, parses the data, and then creates inbound and outbound allow rules for each IP range if they do not already exist.

# Functions
Get-AzureIPs
Downloads the JSON file containing Azure service tags and their respective IP ranges.

URL: The URL of the JSON file to be downloaded.
Download: Uses Invoke-RestMethod to fetch the JSON data.
Error Handling: Catches and outputs an error message if the download fails.
Add-AllowRule
Creates Windows Firewall allow rules for the specified IP range.

# Parameters:
ipRange: The IP range to allow.
groupName: The name of the firewall rule group.
displayName: The display name for the firewall rule.
Existing Rules Check: Checks for existing outbound and inbound rules with the same display name and direction.
Rule Creation: Creates new outbound and inbound rules if they do not already exist.
Write-ServiceSections
Processes each service section's IP addresses from the JSON data and applies firewall rules.

# Parameters:
Data: The JSON data object containing Azure service tags and IP ranges.
Service Processing: Iterates over each service, extracts IP addresses, and calls Add-AllowRule to create firewall rules.
ServiceTags_Public
Main function to orchestrate the overall process.

# Steps:
Calls Get-AzureIPs to download the JSON data.
Checks if data is retrieved successfully.
Calls Write-ServiceSections to process and apply firewall rules.
# Usage
To run the script, simply execute the ServiceTags_Public function. This will initiate the download of the JSON file, parse the IP ranges, and apply the necessary firewall rules.
