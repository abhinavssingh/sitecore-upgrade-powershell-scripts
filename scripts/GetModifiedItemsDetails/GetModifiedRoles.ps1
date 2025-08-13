<#
    .SYNOPSIS
        Export sitecore roles based on date range.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$startDate
$endDate

$dialogParams = @{
  Title            = "Get modified roles and serialization based on date range"
  Description      = "This script exports Sitecore roles modified within a specified date range."
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

function GetRoleDetailsFromCodeDb {
  $sql = @"
USE [{0}]
select [MemberRoleName],[Created] from RolesInRoles where Created > '{1}' and Created <'{2}' order by Created desc
"@

  Import-Function Invoke-SqlCommand
			
  $connection = [Sitecore.Configuration.Settings]::GetConnectionString("core")
  $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $connection
  $dbName = $builder.InitialCatalog
  $query = [string]::Format($sql, $dbName, $startDate, $endDate)
  $records = Invoke-SqlCommand -Connection $connection -Query $query
  return $records
}

function Get-ModifiedRoles {
  try {
    $roleDetails = GetRoleDetailsFromCodeDb
    if ($null -ne $roleDetails -and $roleDetails.Count -gt 0) {
      foreach ($role in $roleDetails) {      
        Export-Role -Identity $role.MemberRoleName
        $role
      }
    }
  }
  catch {
    Write-Host "Error while fetching modified roles: $_" -ForegroundColor Red
  }
  
}


$result = Get-ModifiedRoles |  Where-Object { $_ -ne "True" -and $_ -ne "False" }


#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
    $CurrentTime.hours,
    $CurrentTime.minutes,
    $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 

if ($null -eq $result -or $result.Count -eq 0) {
  Show-Alert "There are no modified roles between start date $($startDate) and end date $($endDate)."
}
else {
  $message = "Total modified roles: $($result.Count)  between start date $($startDate) and end date $($endDate). Serialize data is present into serialization folder."
  Write-Host $message -ForegroundColor Green
  $props = @{
    InfoTitle       = $PSScript.Name
    InfoDescription = "Lists all roles that are modified.$($message)"
    PageSize        = 25
    Title           = $PSScript.Name
  }
    
  $result |
  Show-ListView @props -Property @{Label = "Role Name"; Expression = { $_.MemberRoleName } },
  @{Label = "Created Date"; Expression = { $_.Created } }
}