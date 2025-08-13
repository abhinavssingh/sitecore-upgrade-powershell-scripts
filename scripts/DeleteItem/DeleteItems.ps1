<#
    .SYNOPSIS
        Delets items of a particular node.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$includeNested = $false # default value for nested children

$radioOptions = [ordered]@{
    "Include Nested Children" = 1
}

$dialogParams = @{
    Title            = "Delete Items"
    Description      = "This script deletes items under a specified Sitecore item."
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

# Get the current logged in user
$currentUser = Get-User -Current

function DeleteItems {
    param(
        [string]$ItemPath,
        [bool]$IncludeNested,
        [string[]]$ExcludeTemplates
    )

    try {
        if (![string]::IsNullOrEmpty($ItemPath)) {           
            if ( $IncludeNested ) {
                $children = Get-ChildItem -Path "master:$ItemPath" -Recurse | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }
                foreach ($child in $children) {
                    $child
                    $child | Remove-Item -Force -ErrorAction SilentlyContinue     
                }
                $parent = Get-Item -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }
                $parent
                $parent  | Remove-Item -Force -ErrorAction SilentlyContinue
                        
            }
            else {
                $item = Get-Item -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }
                $item
                $item  | Remove-Item -Force -ErrorAction SilentlyContinue
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

$result = DeleteItems -ItemPath $itemPath -IncludeNested $includeNested -ExcludeTemplates $excludeTemplates |  Where-Object { $_ -ne "True" -and $_ -ne "False" }

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
    Show-Alert "There are no deleted items under $($itemPath)."
}
else {
    $message = "Total deleted items under $($itemPath): $($result.Count)"
    Write-Host $message -ForegroundColor Green
    $props = @{
        InfoTitle       = $PSScript.Name
        InfoDescription = "Lists all items that are deleted.$($message)"
        PageSize        = 25
        Title           = $PSScript.Name
    }
    
    $result |
    Show-ListView @props -Property @{Label = "Name"; Expression = { $_.DisplayName } },
    @{Label = "Path"; Expression = { $_.ItemPath } },
    @{Label = "ItemID"; Expression = { $_.Id } },
    @{Label = "Deleted By"; Expression = { $currentUser.Name } }
}
Close-Window
 

