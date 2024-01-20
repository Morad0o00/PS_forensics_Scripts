# Specify the path to the Sysinternals tools folder
$sysinternalsPath = "D:\DFIR Tools\command line tools"

# Check if the Sysinternals folder exists
if (-not (Test-Path $sysinternalsPath -PathType Container)) {
    Write-Host "Sysinternals folder not found."
    Exit
}

# Set the path environment variable to include Sysinternals tools
$env:PATH += ";$sysinternalsPath"

# Check if a directory path was provided as a command-line argument
if ($args.Count -eq 0) {
    Write-Host "Please provide a directory path as a command-line argument."
    Exit
}

# Get the directory path from the command-line argument
$directoryPath = $args[0]

# Check if the directory exists
if (-not (Test-Path $directoryPath -PathType Container)) {
    Write-Host "Directory not found."
    Exit
}

# Create a folder named "SysinternalsResults" in the current working directory
$resultsFolder = Join-Path $PSScriptRoot "SysinternalsResults"
if (-not (Test-Path $resultsFolder -PathType Container)) {
    New-Item -ItemType Directory -Path $resultsFolder | Out-Null
}

# Get a list of all files in the directory
$files = Get-ChildItem -Path $directoryPath -File

# Initialize arrays to store Sigcheck, DensityCount, and SHA256 results
$sigcheckResults = @()
$densityCountResults = @()
$sha256Results = @()

# Loop through each file and run Sysinternals tools
foreach ($file in $files) {
    Write-Host "Running Sysinternals tools on $($file.FullName)"

    # Run Sigcheck on the file
    $sigcheckResult = & sigcheck.exe $file.FullName

    # Parse Sigcheck output to extract specific details
    $sigcheckDetails = @{
        'FileName'      = $file.Name
        'Verified'      = $sigcheckResult | Select-String 'Verified:' | ForEach-Object { $_ -replace 'Verified:\s+' }
        'LinkDate'      = $sigcheckResult | Select-String 'Link date:' | ForEach-Object { $_ -replace 'Link date:\s+' }
        'Publisher'     = $sigcheckResult | Select-String 'Publisher:' | ForEach-Object { $_ -replace 'Publisher:\s+' }
        'Company'       = $sigcheckResult | Select-String 'Company:' | ForEach-Object { $_ -replace 'Company:\s+' }
        'Description'   = $sigcheckResult | Select-String 'Description:' | ForEach-Object { $_ -replace 'Description:\s+' }
        'Product'       = $sigcheckResult | Select-String 'Product:' | ForEach-Object { $_ -replace 'Product:\s+' }
        'ProdVersion'   = $sigcheckResult | Select-String 'Prod version:' | ForEach-Object { $_ -replace 'Prod version:\s+' }
        'FileVersion'   = $sigcheckResult | Select-String 'File version:' | ForEach-Object { $_ -replace 'File version:\s+' }
        'MachineType'   = $sigcheckResult | Select-String 'MachineType:' | ForEach-Object { $_ -replace 'MachineType:\s+' }
        'SHA256'        = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
    }

    # Add Sigcheck details to the array
    $sigcheckResults += [PSCustomObject]$sigcheckDetails

    # Display Sigcheck results on screen with formatted output
    $sigcheckDetails.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }

    # Run DensityCount on the file
    $densityCountResult = & densitycount.exe $file.FullName

    # Parse DensityCount output to extract Density and Filename
    $densityCountDetails = @{
        'FileName' = $file.Name
        'Density'   = $densityCountResult | Select-String 'Density:' | ForEach-Object { $_ -replace 'Density:\s+' }
    }

    # Add DensityCount details to the array
    $densityCountResults += [PSCustomObject]$densityCountDetails

    # Display DensityCount results on screen with formatted output
    Write-Host "DensityCount Results for $($file.Name):" -ForegroundColor Green
    Write-Host $densityCountResult -ForegroundColor Green
    
    # Calculate SHA256 hash for the file
    $sha256Result = Get-FileHash -Path $file.FullName -Algorithm SHA256

    # Parse SHA256 result to extract specific details
    $sha256Details = @{
        'FileName' = $file.Name
        'SHA256'   = $sha256Result.Hash
    }

    # Add SHA256 details to the array
    $sha256Results += [PSCustomObject]$sha256Details

    # Display SHA256 result on screen in green
    Write-Host "SHA256: $($sha256Details.SHA256)" -ForegroundColor Green
}

# Specify the paths for the CSV files
$sigcheckCsvFilePath = Join-Path $resultsFolder "SigcheckResults.csv"
$densityCountCsvFilePath = Join-Path $resultsFolder "DensityCountResults.csv"
$sha256CsvFilePath = Join-Path $resultsFolder "SHA256Results.csv"

# Export Sigcheck results to a CSV file with reordered columns
$sigcheckResults | Select-Object FileName, ProdVersion, Verified, 'LinkDate', Publisher, Company, Description, Product, FileVersion, MachineType, SHA256 | Export-Csv -Path $sigcheckCsvFilePath -NoTypeInformation

# Export DensityCount results to a CSV file
$densityCountResults | Export-Csv -Path $densityCountCsvFilePath -NoTypeInformation

# Export SHA256 results to a CSV file
$sha256Results | Export-Csv -Path $sha256CsvFilePath -NoTypeInformation
