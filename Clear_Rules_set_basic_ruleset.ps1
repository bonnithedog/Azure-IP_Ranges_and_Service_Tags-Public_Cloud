## Clear all existing outbound rules (optional: use with caution)
#Write-Output "Clearing all existing outbound rules..."
#Get-NetFirewallRule | Remove-NetFirewallRule

# List of allowed IP ranges
$allowedIPs = @(
    # Add your IP ranges here
)

# List of allowed DNS names
$allowedDNS = @(
    "protection.outlook.com",
    "mail.protection.outlook.com",
    "outlook.com",
    "outlook.office.com",
    "outlook.live.com",
    "office.com",
    "office365.com",
    "onedrive.live.com",
    "microsoftonline.com",
    "microsoft.com",
    "microsoft365.com",
    "onmicrosoft.com",
    "sharepoint.com",
    "lync.com",
    "teams.microsoft.com",
    "sway.com",
    "msocdn.com",
    "msocsp.com",
    "msftidentity.com",
    "portal.azure.com",  # Ensure access to Azure Portal
    "portal.azure.com.trafficmanager.net",
    "azureportal.z01.azurefd.net",
    "firstparty-azurefd-prod.trafficmanager.net",
    "shed.dual-low.s-part-0025.t-0009.t-msedge.net",
    "admin.microsoft.com",
    "download.microsoft.com",
    "login.microsoftonline.com",
    "aka.ms",
    "redirectiontool.trafficmanager.net"
    
)

# Create a rule to allow incoming DHCP traffic (UDP port 67)
New-NetFirewallRule -DisplayName "Allow DHCP Inbound" -Direction Inbound -Protocol UDP -LocalPort 67 -Action Allow  -Group "DHCP Rules"

# Create a rule to allow outgoing DHCP traffic (UDP port 68)
New-NetFirewallRule -DisplayName "Allow DHCP Outbound" -Direction Outbound -Protocol UDP -LocalPort 68 -Action Allow  -Group "DHCP Rules"

# Verify the rules have been created
Get-NetFirewallRule -DisplayName "Allow DHCP*"


# DNS Servers
$dnsServers = @("1.1.1.2", "1.0.0.2")

# Set the DNS server for the client
$interfaceAlias = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1 -ExpandProperty Name
Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses ($dnsServers)


# Allow traffic to DNS servers first to ensure DNS resolution works
foreach ($dns in $dnsServers) {
    Write-Output "Allowing traffic to DNS server $dns"
    $existingRuleOutbound = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "Allow DNS Server $dns" -and $_.Direction -eq "Outbound" }
    $existingRuleInbound = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "Allow DNS Server $dns" -and $_.Direction -eq "Inbound" }
    
    if (-not $existingRuleOutbound) {
        New-NetFirewallRule -DisplayName "Allow DNS Server $dns" -Direction Outbound -Action Allow -RemoteAddress $dns -Profile Any -Protocol UDP -RemotePort 53 -Group "DNS Rules"
    }
    if (-not $existingRuleInbound) {
        New-NetFirewallRule -DisplayName "Allow DNS Server $dns" -Direction Inbound -Action Allow -RemoteAddress $dns -Profile Any -Protocol UDP -RemotePort 53 -Group "DNS Rules"
    }
}


# Function to create allow rules for each IP range if not already present
function Add-AllowRule {
    param (
        [string]$ipRange,
        [string]$groupName,
        [string]$displayName
    )
    $existingRuleOutbound = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "$ipRange TCP $displayName" -and $_.Direction -eq "Outbound" }
    $existingRuleInbound = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "$ipRange TCP $displayName" -and $_.Direction -eq "Inbound" }
    
    if (-not $existingRuleOutbound) {
        New-NetFirewallRule -DisplayName "$ipRange TCP $displayName" -Direction Outbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol TCP -Group $groupName | Out-Null
        New-NetFirewallRule -DisplayName "$ipRange UDP $displayName" -Direction Outbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol UDP -Group $groupName | Out-Null
    }
    if (-not $existingRuleInbound) {
        New-NetFirewallRule -DisplayName "$ipRange TCP $displayName" -Direction Inbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol TCP -Group $groupName | Out-Null
        New-NetFirewallRule -DisplayName "$ipRange UDP $displayName" -Direction Inbound -Action Allow -RemoteAddress $ipRange -Profile Any -Protocol UDP -Group $groupName | Out-Null
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


# Allow ICMP traffic
Write-Output "Allowing ICMP traffic..."
$existingRuleOutboundICMP = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "Allow ICMP Outbound" }
$existingRuleInboundICMP = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "Allow ICMP Inbound" }

if (-not $existingRuleOutboundICMP) {
    New-NetFirewallRule -DisplayName "Allow ICMP Outbound" -Direction Outbound -Action Allow -Protocol ICMPv4 -IcmpType 8 -Profile Any -Group "ICMP Rules"
}
if (-not $existingRuleInboundICMP) {
    New-NetFirewallRule -DisplayName "Allow ICMP Inbound" -Direction Inbound -Action Allow -Protocol ICMPv4 -IcmpType 8 -Profile Any -Group "ICMP Rules"
}

# Allow traffic to the specified IP ranges
foreach ($ip in $allowedIPs) {
    Write-Output "Allowing traffic to $ip..."
    Add-AllowRule -ipRange $ip -groupName "Allowed IPs" -displayName "Allow"
}

# Resolve DNS names and allow traffic to the resolved IP addresses
foreach ($dns in $allowedDNS) {
    Write-Output "Resolving DNS: $dns"
    $resolvedIPs = Resolve-DNS -dnsName $dns
    foreach ($ip in $resolvedIPs) {
        Write-Output "Allowing traffic to $ip (resolved from $dns)"
        Add-AllowRule -ipRange $ip -groupName $dns -displayName "Allow $dns"
    }
}




Write-Output "Firewall rules updated successfully."
