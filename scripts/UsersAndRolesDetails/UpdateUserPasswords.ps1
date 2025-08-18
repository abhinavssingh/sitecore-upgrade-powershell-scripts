<#
    .SYNOPSIS
        Update users password through csv file.
    
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
$inputFile = $webRootPath + $uploadFile

Import-Function Invoke-SqlCommand
	
$connection = [Sitecore.Configuration.Settings]::GetConnectionString("core")

# Import CSV data
$userData = Import-Csv -Path $inputFile

if ($null -eq $userData) {
    Write-Host "No data found in the CSV file. Exiting script."
    Close-Window
    return
}
else {
    # Insert into the target database
    foreach ($user in $userData) {
        $userName = $user.UserName
        $password = $user.Password
        $passwordSalt = $user.PasswordSalt
        $isApproved = [int]$user.IsApproved

        # Execute SQL query
        $query = @"
    UPDATE dbo.aspnet_Membership
    SET Password = '$password', 
        PasswordSalt = '$passwordSalt', 
        IsApproved = $isApproved
    WHERE UserId = (
        SELECT UserId FROM dbo.aspnet_Users WHERE UserName = '$userName'
    );
"@

        # Execute SQL query
        Invoke-SqlCommand -Connection $connection -Query $query
        Write-Host "Updated password for user: $userName"
    }
}

Write-Host "CSV import completed successfully!"

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 
