<#
    .SYNOPSIS
        Gets security permission of a particular node.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$includeNested = $false # default value for nested children

$radioOptions = [ordered]@{
    "Include Nested Children" = 1
}

$dialogParams = @{
    Title            = "Get Security Permissions"
    Description      = "This script retrieves items with security permissions set. You can choose to include nested children in the search."
    OkButtonName     = "Execute"
    CancelButtonName = "Close"
    ShowHints        = $true
    
    Parameters       = @(
        @{
            Name    = "radioSelector"
            Title   = "Do you want nested childrens?"
            Editor  = "radio"
            Options = $radioOptions
            Tooltip = "Select whether to enable the feature. If checked, the script will get all nested children recursively."
        }
    )
}
 
$dialogResult = Read-Variable @dialogParams

if ($dialogResult -ne "ok") {
    Write-Host "Script execution cancelled." -ForegroundColor Yellow
    Exit
}

# Get the sitecore context item
$contextItem = $SitecoreContextItem

if (-not $contextItem) {
    Write-Host "No context item found. Exiting script." -ForegroundColor Red
    return
}

$itemPath = $contextItem.Paths.FullPath
if ($null -ne $radioSelector) {
    if ($radioSelector) {
        $includeNested = $true
    }
}

function Get-Permissions {
    param(
        [string]$ItemPath,
        [bool]$IncludeNested
    )

    try {
        if (![string]::IsNullOrEmpty($ItemPath)) {           
            if ( $IncludeNested ) {
                $parent = Get-Item -Path "master:$ItemPath"
                $fields = $parent.Fields
                foreach ($field in $fields) {
                    if ($field.Name -eq "__Security" -and ![string]::IsNullOrEmpty($field.Value)) {
                        $parent
                    }
                }
                $parent
                $children = Get-ChildItem -Path "master:$ItemPath" -Recurse
                foreach ($child in $children) {
                    $fields1 = $child.Fields 
                    foreach ($field1 in $fields1) {
                        if ($field1.Name -eq "__Security" -and ![string]::IsNullOrEmpty($field1.Value)) {
                            $child
                        }
                    } 
                }
                        
            }
            else {
                $item = Get-Item -Path "master:$ItemPath"
                $fields2 = $item.Fields
                foreach ($field2 in $fields2) {
                    if ($field2.Name -eq "__Security" -and ![string]::IsNullOrEmpty($field2.Value)) {
                        $item
                    }
                }
            }
        }
        else {
            Write-Warning "'$ItemPath' is empty."
            return 0
        }
    }
    catch {
        Write-Error $_.Exception.Message
        return $null
    }
}

$result = Get-Permissions -ItemPath $itemPath -IncludeNested $includeNested |  Where-Object { $_ -ne "True" -and $_ -ne "False" }

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 

if ($null -eq $result -or $result.Count -eq 0) {
    Show-Alert "There are no items under $($itemPath)."
}
else {
    $message = "Total items under $($itemPath): $($result.Count)"
    Write-Host $message -ForegroundColor Green
    $props = @{
        InfoTitle       = $PSScript.Name
        InfoDescription = "Lists all items where permission is setup.$($message)"
        PageSize        = 25
        Title           = $PSScript.Name
    }
    
    $result |
    Show-ListView @props -Property @{Label = "Name"; Expression = { $_.DisplayName } },
    @{Label = "Path"; Expression = { $_.ItemPath } },
    @{Label = "ItemID"; Expression = { $_.Id } },
    @{Label = "Permission"; Expression = { $_.Fields["__Security"] } }
}
Close-Window