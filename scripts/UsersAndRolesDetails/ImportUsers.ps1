<#
    .SYNOPSIS
        Import Users through csv file.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Script Execution Started"

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
$serializedFolderPath = "\App_Data\serialization\security\sitecore\Users\{0}.user"
$serializedPath = $webRootPath + $serializedFolderPath
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
                $serializedPath = $serializedPath -f $row.UserLocalName
                Import-User -Path $serializedPath
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