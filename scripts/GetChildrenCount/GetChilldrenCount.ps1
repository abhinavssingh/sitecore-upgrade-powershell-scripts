<#
    .SYNOPSIS
        Returns all children count of a particular node.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$includeNested = $false # default value for nested children

$radioOptions = [ordered]@{
    "Include Nested Children" = 1
}

$dialogParams = @{
    Title            = "Get Children Count"
    Description      = "This script retrieves the count of all children for a specified Sitecore item."
    OkButtonName     = "Execute"
    CancelButtonName = "Close"
    ShowHints        = $true
    
    Parameters       = @(
        @{
            Name    = "radioSelector"
            Title   = "Do you want nested childrens count?"
            Editor  = "radio"
            Options = $radioOptions
            Tooltip = "Select whether to enable the feature. If checked, the script will count all nested children recursively."
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

if($treeListSelector.length -ge 1) {
    $excludeTemplates = $treeListSelector | ForEach-Object { $_.ID }
}


function Get-SitecoreChildrenCount {
    param(
        [string]$ItemPath,
        [bool]$IncludeNested,
        [string[]]$ExcludeTemplates
    )

    try {
        if (![string]::IsNullOrEmpty($ItemPath)) {
            $children = 0
            if ( $IncludeNested ) {
                $children = Get-ChildItem -Path "master:$ItemPath" -Recurse | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }              
            }
            else {
                    $children = Get-ChildItem -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }
                }
                return $children.Count
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

$childrenCount = Get-SitecoreChildrenCount -ItemPath $itemPath -IncludeNested $includeNested -ExcludeTemplates $excludeTemplates


Write-Host "`nscript execution completed" -ForegroundColor Green
if ($childrenCount -eq 0) {
    Show-Alert "There are no childrens under $($itemPath)."
}
else {
    $message = "Total childrens under $($itemPath): $($childrenCount)"
    Show-Alert $message
    Write-Host $message -ForegroundColor Green
}

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host "`nExecution Time: $([string]::Format("{0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds))" -ForegroundColor Yellow

 

