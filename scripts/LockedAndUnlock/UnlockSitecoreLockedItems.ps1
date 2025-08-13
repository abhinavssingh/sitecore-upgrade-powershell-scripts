<#
    .SYNOPSIS
        Unlock all children of a particular node.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$includeNested = $false # default value for nested children

$radioOptions = [ordered]@{
    "Include Nested Children" = 1
}

$dialogParams = @{
    Title            = "Unlock Sitecore Locked Items"
    Description      = "This script will unlock all locked items under the selected Sitecore item. You can choose to include nested children or not."
    OkButtonName     = "Execute"
    CancelButtonName = "Close"
    ShowHints        = $true
    
    Parameters       = @(
        @{
            Name    = "radioSelector"
            Title   = "Do you want nested childrens count?"
            Editor  = "radio"
            Options = $radioOptions
            Tooltip = "Select whether to enable the feature. If checked, the script will get all nested children recursively."
        }
        @{
            Name    = "treeListSelector"
            Title   = "Template Exclusion Filter"
            Editor  = "treelist"
            Source  = "DataSource=/sitecore/templates/Project&DatabaseName=master"
            Tooltip = "Select one or more from list"
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
$excludeTemplates = @()

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

if ($treeListSelector.length -ge 1) {
    $excludeTemplates = $treeListSelector | ForEach-Object { $_.ID }
}

# Function to unlock an item 
function Unlock-SitecoreItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ItemPath,
        [Parameter(Mandatory = $true)]
        [bool]$IncludeNested,
        [string[]]$ExcludeTemplates = @()
    )

    if (![string]::IsNullOrEmpty($ItemPath)) {
        if ($IncludeNested) {
            # Get the item using its path
            $items = Get-ChildItem -Path "master:$ItemPath" -Recurse | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }

            # Check if the item exists
            foreach ($item in $items) {
                $languages = $item.languages

                foreach ($language in $languages) {
                    $langPath = $item.Paths.FullPath
                    $langItem = Get-Item -Path "master:$langPath" -Language $language | Where-Object { $_.Versions.GetVersions($true).Count -gt 0 }
                    # Check if the item is actually locked
                    if ($null -ne $langItem -and $langItem.Locking.IsLocked()) {
                        # Unlock the item
                        $langItem.Editing.BeginEdit()
                        $langItem.Locking.Unlock()
                        $langItem.Editing.EndEdit()
                        Write-Host "Item unlocked: $($langItem.Paths.FullPath)"
                        $langItem

                    }
                    else {
                        Write-Host "Item $($item.Id) does not exist in $($language) language."
                    }
                }
            }
        }
        else {
            # Get the item using its path
            $items = Get-ChildItem -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }

            # Check if the item exists
            foreach ($item in $items) {
                $languages = $item.languages

                foreach ($language in $languages) {
                    $langPath = $item.Paths.FullPath
                    $langItem = Get-Item -Path "master:$langPath" -Language $language | Where-Object { $_.Versions.GetVersions($true).Count -gt 0 }
                    # Check if the item is actually locked
                    if ( $null -ne $langItem) {
                        if ($langItem.Locking.IsLocked()) {
                            # Unlock the item
                            $langItem.Editing.BeginEdit()
                            $langItem.Locking.Unlock()
                            $langItem.Editing.EndEdit()
                            Write-Host "Item unlocked: $($langItem.Paths.FullPath)"
                            $langItem
                        }
                        else {
                            Write-Host "Item $($item.Id) is not locked in $($language) language."
                        }
                    }
                    else {
                        Write-Host "Item $($item.Id) does not exist in $($language) language."
                    }
                }

            }
        }
    }    
    else {
        Show-Alert "Item not found: $ItemPath"
    }
}


$result = Unlock-SitecoreItem -itemPath $itemPath -IncludeNested $includeNested -ExcludeTemplates $excludeTemplates |  Where-Object { $_ -ne "True" -and $_ -ne "False" }

Write-Host "`nscript execution completed" -ForegroundColor Green

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1

if ($null -eq $result -or $result.Count -eq 0) {
    Show-Alert "There are no locked childrens under $($itemPath)."
}
else {
    $message = "Total locked childrens under $($itemPath): $($result.Count)"
    Write-Host $message -ForegroundColor Green
    $props = @{
        InfoTitle       = $PSScript.Name
        InfoDescription = "Lists all items that are locked.$($message)"
        PageSize        = 25
        Title           = $PSScript.Name
    }
    
    $result |
    Show-ListView @props -Property @{Label = "Name"; Expression = { $_.DisplayName } },
    @{Label = "Path"; Expression = { $_.ItemPath } },
    @{Label = "ItemID"; Expression = { $_.Id } },
    @{Label = "ItemLanguage"; Expression = { $_.Language } },
    @{Label = "LockedBy"; Expression = { $_.Locking.GetOwner() } }
}
Close-Window

