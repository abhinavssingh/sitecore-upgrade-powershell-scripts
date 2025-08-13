<#
    .SYNOPSIS
        Export items of a particular node.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$includeNested = $false # default value for nested children

$radioOptions = [ordered]@{
    "Include Nested Children" = 1
}

$dialogParams = @{
    Title            = "Quick Serialization - Export Items"
    Description      = "This script exports items from a specific node in Sitecore, with options to include nested children and filter by template exclusion."
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

function SerializeItems {
    param(
        [string]$ItemPath,
        [bool]$IncludeNested,
        [array]$ExcludeTemplates
    )

    try {
        if (![string]::IsNullOrEmpty($ItemPath)) {           
            if ( $IncludeNested ) {
                $parent = Get-Item -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }
                $parent
                Export-Item -path master:$ItemPath
                $children = Get-ChildItem -Path "master:$ItemPath" -Recurse | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }
                foreach ($child in $children) {
                    $child
                    $path = $child.Paths.FullPath
                    Export-Item -path master:$path    
                }
                        
            }
            else {
                $item = Get-Item -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }
                $item
                Export-Item -path master:$ItemPath
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

$result = SerializeItems -ItemPath $itemPath -IncludeNested $includeNested -ExcludeTemplates $excludeTemplates |  Where-Object { $_ -ne "True" -and $_ -ne "False" }

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 

if ($null -eq $result -or $result.Count -eq 0) {
    Show-Alert "There are no serialization items under $($itemPath)."
}
else {
    $message = "Total serialized items under $($itemPath): $($result.Count)"
    Write-Host $message -ForegroundColor Green
    $props = @{
        InfoTitle       = $PSScript.Name
        InfoDescription = "Lists all items that are serialized.$($message)"
        PageSize        = 25
        Title           = $PSScript.Name
    }
    
    $result |
    Show-ListView @props -Property @{Label = "Name"; Expression = { $_.DisplayName } },
    @{Label = "Path"; Expression = { $_.ItemPath } },
    @{Label = "ItemID"; Expression = { $_.Id } },
    @{Label = "Serialized By"; Expression = { $currentUser.Name } }
}
Close-Window