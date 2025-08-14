<#
    .SYNOPSIS
        Get deleted items from Recycle Bin.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$startDate
$endDate

$dialogParams = @{
    Title            = "Gets Deleted Items from Recycle Bin"
    Description      = "This script retrieves items deleted from the Sitecore Recycle Bin within a specified date range. It allows you to select a start and end date for the search, and outputs the results to a CSV file."
    OkButtonName     = "Execute"
    CancelButtonName = "Close"
    ShowHints        = $true
    
    Parameters       = @(
        @{
            Name    = "startDateSelector"
            Title   = "Start Date Selector"
            Editor = "datetime"
            Value   = [System.DateTime]::Now
            Tooltip = "Select a date and time"
        }
        @{
            Name    = "endDateSelector"
            Title   = "End Date Selector"
            Editor = "datetime"
            Value   = [System.DateTime]::Now
            Tooltip = "Select a date and time"
        }
    )
}
 
$dialogResult = Read-Variable @dialogParams

if ($dialogResult -ne "ok") {
    Write-Host "Script execution cancelled." -ForegroundColor Yellow
    Exit
}

if ($startDateSelector -ne [System.DateTime]::MinValue -and $endDateSelector -ne [System.DateTime]::MinValue) {
    $startDate = $startDateSelector
    $endDate = $endDateSelector
}

# Get the Recycle Bin archive
$database = Get-Database -Name "master"
$archiveName = "recyclebin"
$archive = Get-Archive -Database $database -Name $archiveName
$allRecycleBinEntries = Get-ArchiveItem -Archive $archive
$deletedItems = @{}

if ($allRecycleBinEntries) {
    Write-Host "Searching recycle bin for items deleted between $($startDate.ToShortDateString()) and $($endDate.ToShortDateString())..."

    foreach ($entry in $allRecycleBinEntries) {
        # ArchiveLocalDate is the local date and time the item was deleted
        if ($entry.ArchiveLocalDate -ge $startDate -and $entry.ArchiveLocalDate -le $endDate) {
            $key = $entry.ItemId.ToString() # Use ItemId as key
            $itemObject = [PSCustomObject]@{
                Name            = $entry.Name
                ItemID          = $entry.ItemId.ToString() # Convert Sitecore ID (GUID) to string
                OriginalPath    = $entry.OriginalLocation
                DeletedBy       = $entry.ArchivedBy
                DeletionDate    = $entry.ArchiveLocalDate
                ArchivalId      = $entry.ArchivalId.ToString() # Unique ID within the archive, useful for restoration
            }
            $deletedItems[$key]= $itemObject # Add the custom object to our array
        }
    }
}
else {
    Write-Host "Recycle Bin archive not found."
}

# Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
[System.String]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
    $CurrentTime.hours,
    $CurrentTime.minutes,
    $CurrentTime.seconds) | Out-Null

Start-Sleep 1

if ($deletedItems.Count -eq 0) {
    Show-Alert "No deleted items found in the specified date range."
}
else {
    $deletedItems.Values | Show-ListView -Title $PSScript.Name -InfoDescription "`nFound $($deletedItems.Count) deleted items in the specified date range between $($startDate.ToShortDateString()) and $($endDate.ToShortDateString())." -PageSize 25
}

Close-Window