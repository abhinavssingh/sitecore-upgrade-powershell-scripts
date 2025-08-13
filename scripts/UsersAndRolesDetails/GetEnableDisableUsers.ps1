$Time = [System.Diagnostics.Stopwatch]::StartNew()

$radioOptions = [ordered]@{
    "Enabled Users"  = 1
    "Disabled Users" = 2
}

$dialogParams = @{
    Title            = "Get Enable/Disable Users"
    Description      = "This script retrieves the count of enabled and disabled users in Sitecore."
    OkButtonName     = "Execute"
    CancelButtonName = "Close"
    ShowHints        = $true
    
    Parameters       = @(
        @{
            Name    = "radioSelector"
            Title   = "Select User Status"
            Editor  = "radio"
            Options = $radioOptions
            Tooltip = "Choose the type of users to retrieve."
        }
    )
}
 
$dialogResult = Read-Variable @dialogParams

if ($dialogResult -ne "ok") {
    Write-Host "Script execution cancelled." -ForegroundColor Yellow
    Exit
}

function Get-EnableDisableUsers {
    try {
        $users = Get-User -Filter *
        if ($users.Count -eq 0) {
            Write-Host "No users found." -ForegroundColor Yellow
            return
        }
        if ($radioSelector -eq 1) {
            $enabledUsers = $users | Where-Object { $_.Profile.State -ne 'Disabled' } 
            if ($enabledUsers.Count -gt 0) {
                foreach ($euser in $enabledUsers) {
                    $euser
                }
            }
        }
        elseif ($radioSelector -eq 2) {
            $disabledUsers = $users | Where-Object { $_.Profile.State -eq 'Disabled' } 
            if ($disabledUsers.Count -gt 0) {
                foreach ($duser in $disabledUsers) {
                    $duser
                }
            }
        }
    }
    catch {
        Write-Host "An error occurred while retrieving user details: $_" -ForegroundColor Red
    }    
}

$result = Get-EnableDisableUsers

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 
 
if ($null -eq $result -or $result.Count -eq 0) {
    Show-Alert "No user details found."
}
else {
    if ($radioSelector -eq 1) {
        $message = "Total enabled users found: $($result.Count)"
        Write-Host $message -ForegroundColor Green
        $props = @{
            InfoTitle       = $PSScript.Name
            InfoDescription = "Lists all enabled users.$($message)"
            PageSize        = 25
            Title           = $PSScript.Name
        }
    
        $result |
        Show-ListView @props -Property @{Label = "User Name"; Expression = { $_.DisplayName } },
        @{Label = "Domain"; Expression = { $_.Domain } },
        @{Label = "Enabled"; Expression = { $_.IsEnabled } }

    }
    elseif ($radioSelector -eq 2) {
        $message = "Total disabled users found: $($result.Count)"
        Write-Host $message -ForegroundColor Green
        $props = @{
            InfoTitle       = $PSScript.Name
            InfoDescription = "Lists all disabled users.$($message)"
            PageSize        = 25
            Title           = $PSScript.Name
        }
    
        $result |
        Show-ListView @props -Property @{Label = "User Name"; Expression = { $_.DisplayName } },
        @{Label = "Domain"; Expression = { $_.Domain } },
        @{Label = "Enabled"; Expression = { $_.IsEnabled } }
    }
}
Close-Window