# Define the DNS name to check
$dnsName = "matetask1369202553.uksouth.cloudapp.azure.com"
$reportFile = "DNS_report.txt"

# Initialize the report content
$reportContent = @"
DNS Report for $dnsName
=========================
"@

try {
    # Check DNS resolution
    Write-Output "Performing DNS lookup..."
    $nslookupResult = nslookup $dnsName
    $reportContent += "DNS Lookup Result:`n$nslookupResult`n`n"

    # Test connection to the DNS name
    Write-Output "Testing connection to the DNS name..."
    $testConnectionResult = Test-Connection -ComputerName $dnsName -Count 4
    $pingResults = $testConnectionResult | ForEach-Object { "$($_.Address) - $($_.StatusCode) - $($_.ResponseTime)ms" }
    $reportContent += "Test Connection Result:`n$($pingResults -join "`n")`n`n"

    # Debugging: Explicitly output the DNS name variable
    Write-Output "DNS Name: $dnsName"

    # Attempt to make a web request to the DNS name on port 8080
    Write-Output "Constructing the URI..."
    $uri = "http://$dnsName:8080/api/"
    $reportContent += "Attempting to access: $uri`n"
    Write-Output "Attempting to access: $uri"

    try {
        $response = Invoke-WebRequest -Uri $uri -ErrorAction Stop
        $reportContent += "HTTP Status Code: $($response.StatusCode)`n"
        if ($response.StatusCode -eq 200) {
            $reportContent += "Web application is running - OK`n"
        } else {
            $reportContent += "Web application returned a non-200 status code`n"
        }
    } catch {
        $reportContent += "Web request failed: $($_.Exception.Message)`n"
    }
} catch {
    $reportContent += "An error occurred: $($_.Exception.Message)`n"
}

# Write the report content to the file
$reportContent | Out-File -FilePath $reportFile -Encoding utf8

# Output a message to indicate the report has been generated
Write-Output "DNS report has been generated: $reportFile"
