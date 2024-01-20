# Function to query VirusTotal for a given hash
function Get-VirusTotalScan($apiKey, $hash) {
    $url = "https://www.virustotal.com/api/v3/files/$hash"
    $headers = @{
        "x-apikey" = $apiKey
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    if ($response.data.attributes.last_analysis_stats.malicious -gt 0) {
        return "Malicious"
    } else {
        return "Clean"
    }
}

# Get the current working directory
$currentDirectory = Get-Location

# Specify the path to the folder containing files (use the current directory)
$folderPath = $currentDirectory.Path

# Specify the path for the CSV file
$csvFilePath = Join-Path $currentDirectory "HashesWithVT.csv"

# Specify your VirusTotal API key
$apiKey = "585cfc0d93c485b2caa4b0b33d550a25e9980a5855ffaa4c9025da4291ffcc48"

# Get a list of all files in the folder
$files = Get-ChildItem -Path $folderPath -File

# Initialize an array to store hash data
$hashData = @()

# Loop through each file and generate SHA-256 hash
foreach ($file in $files) {
    $filePath = $file.FullName
    $hash = Get-FileHash -Path $filePath -Algorithm SHA256

    # Query VirusTotal for the hash
    $vtResult = Get-VirusTotalScan -apiKey $apiKey -hash $hash.Hash

    # Create a hash object with file name, SHA-256 hash, file path, and VirusTotal result
    $hashObject = [PSCustomObject]@{
        'FileName' = $file.Name
        'SHA256Hash' = $hash.Hash
        'FilePath' = $file.FullName
        'VirusTotalResult' = $vtResult
    }

    # Add the hash object to the array
    $hashData += $hashObject
}

# Export the hash data to a CSV file
$hashData | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "Hashes exported to $csvFilePath."
