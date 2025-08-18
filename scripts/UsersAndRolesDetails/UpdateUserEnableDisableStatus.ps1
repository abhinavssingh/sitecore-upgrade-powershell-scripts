<#
    .SYNOPSIS
        Update users status through csv file.
    
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

if ($null -eq $csvData) {
    Write-Host "No data found in the CSV file. Exiting script."
    Close-Window
    return
}
else {
    foreach ($row in $csvData) {
        $userName = $row.UserName
        $user = Get-User -Filter $userName
        $userDetails = Get-User -Identity $user.Name
        if ($user.Count -gt 0) {
            if ($row.NewStatus.ToLower() -eq "false") {
                $key = "${userName}"
                $itemData = New-Object PSObject -Property @{
                    "UserName"  = $userName
                    "OldStatus" = $userDetails.IsEnabled
                    "NewStatus" = $row.NewStatus
                }

                # Add the data to the hashtable with the composite key
                $data[$key] = $itemData
                Disable-User -Identity $userName
                Write-Output "user-" $userName "disabled"
            }
            if ($row.NewStatus.ToLower() -eq "true") {
                $key = "${userName}"
                $itemData = New-Object PSObject -Property @{
                    "UserName"  = $userName
                    "OldStatus" = $userDetails.IsEnabled
                    "NewStatus" = $row.NewStatus
                }
                # Add the data to the hashtable with the composite key
                $data[$key] = $itemData
                Enable-User -Identity $userName
                Write-Output "user-" $userName "enabled"
            }
        }
        else {
            Write-Output "user-" $userName "not found"
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
    Show-Alert "No user details found."
}
else {
    $data.Values | Show-ListView -Title $PSScript.Name -InfoDescription "`nTotal users updated: $($data.Count)" -PageSize 25
}

Close-Window
