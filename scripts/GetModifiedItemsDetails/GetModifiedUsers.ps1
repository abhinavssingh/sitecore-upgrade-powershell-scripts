<#
    .SYNOPSIS
        Export sitecore users based on date range.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$startDate
$endDate

$dialogParams = @{
    Title            = "Get modified users and serialization based on date range"
    Description      = "This script exports Sitecore users modified within a specified date range."
    OkButtonName     = "Execute"
    CancelButtonName = "Close"
    ShowHints        = $true
    
    Parameters       = @(
        @{
            Name    = "startDateSelector"
            Title   = "Start Date Selector"
            Editor  = "datetime"
            Value   = [System.DateTime]::Now
            Tooltip = "Select a date and time"
        }
        @{
            Name    = "endDateSelector"
            Title   = "End Date Selector"
            Editor  = "datetime"
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

function Get-ModifiedUsers {
    try {
        $users = Get-User -Filter *
        # Iterate through each user
        foreach ($user in $users) {
            # Get the MembershipUser object
            $membershipUser = [System.Web.Security.Membership]::GetUser($user.Name)

            # Get the creation and last updated dates
            $creationDate = $membershipUser.CreationDate
            $lastUpdatedDate = $membershipUser.LastActivityDate

            if ($creationDate -ge $startDate -and $lastUpdatedDate -lt $endDate) {
                Export-User -Identity $user.Name
                $user
            }
        }
    }
    catch {
        Write-Host "Error while fetching modified users: $_" -ForegroundColor Red
    }
}

$result = Get-ModifiedUsers |  Where-Object { $_ -ne "True" -and $_ -ne "False" }

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 

if ($null -eq $result -or $result.Count -eq 0) {
    Show-Alert "There are no modified users between start date $($startDate) and end date $($endDate)."
}
else {
    $message = "Total modified users: $($result.Count)  between start date $($startDate) and end date $($endDate). Serialize data is present into serialization folder."
    Write-Host $message -ForegroundColor Green
    $props = @{
        InfoTitle       = $PSScript.Name
        InfoDescription = "Lists all users that are modified.$($message)"
        PageSize        = 25
        Title           = $PSScript.Name
    }
    
    $result |
    Show-ListView @props -Property @{Label = "User Name"; Expression = { $_.Name } },
    @{Label = "Created Date"; Expression = { $_.CreationDate } },
    @{Label = "Local Name"; Expression = { $_.LocalName } }
}
