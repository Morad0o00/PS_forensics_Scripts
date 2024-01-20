# Get the current working directory
$directoryPath = Get-Location

# Specify the extensions you want to organize
$extensionsToOrganize = @(".pdf", ".txt", ".docx", ".xlsx", ".jpg", ".png",".exe", ".msi" ,".csv",".rar")

# Iterate through each file in the directory
Get-ChildItem $directoryPath -File | ForEach-Object {
    $extension = $_.Extension

    # Check if the extension is in the list to organize
    if ($extensionsToOrganize -contains $extension) {
        # Create the destination folder if it doesn't exist
        $destinationFolder = Join-Path $directoryPath $extension
        New-Item -ItemType Directory -Force -Path $destinationFolder

        # Move the file to the corresponding folder
        $_ | Move-Item -Destination $destinationFolder
    }
}
