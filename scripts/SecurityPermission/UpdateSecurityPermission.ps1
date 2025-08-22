<#
    .SYNOPSIS
        Update security permission through csv file.
    
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
        $itemPath = $row.Path
        $item = Get-Item -Path "master:$itemPath"
        if($item)
        {
            $key = "$($item.ID)-$($item.Language.Name)"
            $oldValue = $item.Fields["__Security"].Value
            $item.Edit.BeginEdit()
            $item.Fields["__Security"] = $row.Permission
            $item.Edit.EndEdit()
            $itemData = @{
                "ItemID" = $item.ID
                "ItemPath" = $item.Paths.FullPath
                "Language" = $item.Language.Name
                "OldValue" = $oldValue
                "NewValue" = $row.Permission
            }
            $data[$key] = $itemData

        }
        else {
            Write-Host "Item not found at path: $itemPath" -ForegroundColor Red
            continue
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
    Show-Alert "No permissions updated."
}
else {
    $data.Values | Show-ListView -Title $PSScript.Name -InfoDescription "`nTotal permission updated: $($data.Count)" -PageSize 25
}

Close-Window