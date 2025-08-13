$Time = [System.Diagnostics.Stopwatch]::StartNew()

function Get-UserDetails {
    try {
        $users = Get-User -Filter *
        if($users.Count -eq 0) {
            Write-Host "No users found." -ForegroundColor Yellow
            return
        }
        foreach ($user in $users) {
                $user
        } 
    }
    catch {
        Write-Host "An error occurred while retrieving user details: $_" -ForegroundColor Red
    }

    
}



$result = Get-UserDetails

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
    $message = "Total users found: $($result.Count)"
    Write-Host $message -ForegroundColor Green
    $props = @{
        InfoTitle       = $PSScript.Name
        InfoDescription = "Lists all users.$($message)"
        PageSize        = 25
        Title           = $PSScript.Name
    }
    
    $result |
    Show-ListView @props -Property @{Label = "User Name"; Expression = { $_.DisplayName } },
    @{Label = "Domain"; Expression = { $_.Domain } },
    @{Label = "IsAdministrator"; Expression = { $_.IsAdministrator } },
    @{Label = "Enabled"; Expression = { $_.IsEnabled } },
    @{Label = "Roles"; Expression = { Get-User -Identity $_.Name | Select-Object -ExpandProperty MemberOf | ForEach-Object { $_.Name } } }
}
Close-Window