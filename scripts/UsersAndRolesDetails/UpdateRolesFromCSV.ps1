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

if($null -eq $uploadFile) {
    Write-Host "No file selected. Exiting script."
    Close-Window
    return
}

# Define the path to the csv file
$inputFile = $webRootPath + $uploadFile

# Load the csv data into a variable
$csvData = Import-Csv -Path $inputFile

foreach ($row in $csvData) {
    $username = $row.UserName
    $oldRoles = $row.RemoveRoles
    $newRoles = $row.AddRoles
    $addRoles = $row.AddRoles -split ";" | Where-Object { $_ } #remove empty values
    $removeRoles = $row.RemoveRoles -split ";" | Where-Object { $_ } #remove empty values
    # Get the Sitecore user object
    $sitecoreUser = Get-User -Identity $username
    if ($sitecoreUser) {

        $key = "${userName}"
        $itemData = New-Object PSObject -Property @{
            "UserName" = $userName
            "OldRoles" = $oldRoles
            "NewRoles" = $newRoles
        }

        # Add the data to the hashtable with the composite key
        $data[$key] = $itemData
        
        # Remove roles
        foreach ($roleName in $removeRoles) {
            try {
                Remove-RoleMember -Identity $roleName -Members $sitecoreUser.Name
                Write-Host "Removed role '$roleName' from user '$username'"
            }
            catch {
                Write-Error "Error removing role '$roleName' from user '$username': $($_.Exception.Message)"
            }
        }

        # Add roles
        foreach ($roleName in $addRoles) {
            try {
                Add-RoleMember -Identity $roleName -Members $sitecoreUser.Name
                Write-Host "Added role '$roleName' to user '$username'"
            }
            catch {
                Write-Error "Error adding role '$roleName' to user '$username': $($_.Exception.Message)"
            }
        }
 
    }
    else {
        Write-Warning "User '$username' not found."
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
    Show-Alert "No roles details found."
}
else {
    $data.Values | Show-ListView -Title $PSScript.Name -InfoDescription "`nTotal roles updated: $($data.Count)" -PageSize 25
}

Close-Window