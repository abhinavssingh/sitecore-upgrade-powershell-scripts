<#
    .SYNOPSIS
        Update users Profile data through csv file.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Script Execution Started"

# Create a hashtable to store the extracted data, where the key is a combination of item ID and language
$data = @{}

function GetHostName {
    $contentItemId = "{0DE95AE4-41AB-4D01-9EB0-67441B7C2450}"
    $contentItem = Get-Item -Path master: -Id $contentItemId
    $urlOptions = New-Object Sitecore.Links.UrlOptions
    $urlOptions.AlwaysIncludeServerUrl = $true;
    $pageUrl = [Sitecore.Links.LinkManager]::GetItemUrl($contentItem, $urlOptions);
    $stringArray = $pageUrl.split("/")
    return $stringArray[2]
}

# write output file
$hostName = GetHostName
$webRootPath = Get-Website -Name $hostName | Select-Object -ExpandProperty PhysicalPath

$uploadFile = Show-ModalDialog -HandleParameters @{
    "h" = "FileBrowser";
} -Control "FileBrowser" -Width 500

if ($null -eq $uploadFile) {
    Write-Host "No file selected. Exiting script."
    Close-Window
    return
}

# Define the path to the csv file
$inputFile = $webRootPath + $uploadFile

# Load the csv data into a variable
$csvData = Import-Csv -Path $inputFile

if ( $null -eq $csvData) {
    Write-Host "No data found in the CSV file. Exiting script."
    Close-Window
    return
}

else {
    foreach ($row in $csvData) {
        $userName = $row.UserName
        $user = Get-User -Filter $row.UserName

        if ($user) {
            Write-Host "User found: $($user.Name)"
            $key = "${userName}"
            $oldValue = $user.Profile.GetCustomProperty($($row.PropertyName))
            $itemData = New-Object PSObject -Property @{
                "UserName"      = $userName
                "Property Name" = $row.PropertyName
                "Old Value"     = $oldValue
                "New Value"     = $row.PropertyValue
            }
            # Set custom properties
            Write-Host "Setting custom properties..."
            Set-User -Identity $userName -CustomProperties @{
                $row.PropertyName = $row.PropertyValue
            }
            # Add the data to the hashtable with the composite key
            $data[$key] = $itemData
            Write-Host "Custom properties updated and saved for $($user.Name)."

        }
        else {
            Write-Host "User with identity '$userIdentity' not found."
        }
    }
}

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 

if ($data.Count -eq 0) {
    Show-Alert "No users details found."
}
else {
    $data.Values | Show-ListView -Title $PSScript.Name -InfoDescription "`nTotal users custom profile updated: $($data.Count)" -PageSize 25
}

Close-Window