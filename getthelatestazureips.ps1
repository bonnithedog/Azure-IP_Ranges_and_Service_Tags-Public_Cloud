# If you want to automate the solution to fetch latest file. You can use this function.
function Get-NewAzureIPs {
    # URL of the download page
    $downloadPageUrl = "https://www.microsoft.com/en-us/download/details.aspx?id=56519&msockid=088347aa29b462b33e10533928e36384"
    
    # Download the webpage content
    try {
        $webpageContent = Invoke-WebRequest -Uri $downloadPageUrl -Method Get -ErrorAction Stop
    } catch {
        Write-Output "Failed to download the webpage content: $_"
        return
    }

    # Parse the HTML to find the download link
    try {
        $downloadLink = $webpageContent.Links | Where-Object { $_.href -match "download.microsoft.com" } | Select-Object -First 1 -ExpandProperty href
    } catch {
        Write-Output "Failed to parse the HTML or find the download link."
        return
    }

    if (-not $downloadLink) {
        Write-Output "Failed to locate the download link."
        return
    }

    # Download the latest JSON file content
    try {
        $jsonContent = Invoke-RestMethod -Uri $downloadLink -Method Get -ErrorAction Stop
    } catch {
        Write-Output "Failed to download the JSON file: $_"
        return
    }

    # Convert JSON content to string and get the first 20 lines
    $jsonContent | ConvertTo-Json -Depth 10 | Select-String -Pattern "^" | Select-Object -First 20
}

# Call the function Get-AzureIPs
Get-NewAzureIPs
