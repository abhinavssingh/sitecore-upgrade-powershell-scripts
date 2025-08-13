$Time = [System.Diagnostics.Stopwatch]::StartNew()

$userData = @{}

function Get-UserDetailsWithProfileDetails {
    try {
        $users = Get-User -Filter *
        if ($users.Count -eq 0) {
            Write-Host "No users found." -ForegroundColor Yellow
            return
        }
        foreach ($user in $users) {
            $key = $user.Name
            $tempData = @{}
            # Get the MembershipUser object
            $membershipUser = [System.Web.Security.Membership]::GetUser($user.Name)
            # Get all custom property names from the user's profile.
            $customPropertyNames = $user.Profile.GetCustomPropertyNames()
    
            # Iterate through the custom properties and add each one to our custom object.
            foreach ($propName in $customPropertyNames) {
                $key1 = $propName
                $Value = $user.Profile.GetCustomProperty($propName)
                $userCustomProperty = [PSCustomObject]@{
                    Name  = $propName
                    Value = $Value
                }
                $tempData[$key1] = $userCustomProperty

            }
            $userDetails = [PSCustomObject]@{
                Name             = $user.Name
                Domain           = $user.Domain
                Email            = $user.Profile.Email
                IsAdministrator  = $user.IsAdministrator
                CreationDate     = $membershipUser.CreationDate
                LastLoginDate    = $membershipUser.LastLoginDate
                LastActivityDate = $membershipUser.LastActivityDate
                IsLockedOut      = $user.IsLockedOut
                IsEnabled        = $user.Profile.State
                Roles            = $user.Roles.Name -join ", "
                Comment          = $user.Profile.Comment
                CustomProperties = $tempData.GetEnumerator()  | ForEach-Object { "$($_.Name)=$($_.Value)" } | Out-String | ForEach-Object { $_.Trim() -replace "`r`n", "," }
            }

            $userData[$key] = $userDetails
            $tempData.Clear()
        } 
        return $userData.Values
    }
    catch {
        Write-Host "An error occurred while retrieving user details: $_" -ForegroundColor Red
    }  
}

$result = Get-UserDetailsWithProfileDetails -ErrorAction SilentlyContinue

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
    $result | Show-ListView -InfoDescription "Lists all users with complete details. Total users count: $($result.Count)." -PageSize 25 -Title $PSScript.Name 
}

Close-Window