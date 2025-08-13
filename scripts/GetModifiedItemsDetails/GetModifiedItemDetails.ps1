<#
    .SYNOPSIS
        Export items of a particular node.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$includeNested = $false # default value for nested children
$startDate
$endDate
$startNodeId
$users = @()

$radioOptions = [ordered]@{
    "Include Nested Children" = 1
}

$dialogParams = @{
    Title            = "Get modified items details and serialization based on date range"
    Description      = "This script retrieves modified items under a specific item path and serializes them based on a date range. You can choose to include nested children and filter by template exclusion."
    OkButtonName     = "Execute"
    CancelButtonName = "Close"
    ShowHints        = $true
    
    Parameters       = @(
        @{
            Name    = "contentTreeListSelector"
            Title   = "Select Content Node"
            Editor  = "treelist"
            Source  = "DataSource=/sitecore/content&DatabaseName=master"
            Tooltip = "Select one item from the content tree"
        }
        @{
            Name    = "radioSelector"
            Title   = "Do you want nested childrens count?"
            Editor  = "radio"
            Options = $radioOptions
            Tooltip = "Select whether to enable the feature. If checked, the script will get all nested children recursively."
        }
        @{
            Name    = "startDateSelector"
            Title   = "Start Date Selector"
            Editor = "datetime"
            Value   = [System.DateTime]::Now
            Tooltip = "Select a date and time"
        }
        @{
            Name    = "endDateSelector"
            Title   = "End Date Selector"
            Editor = "datetime"
            Value   = [System.DateTime]::Now
            Tooltip = "Select a date and time"
        }
        @{
            Name = "userSelector"
            Title = "User Selector"
            Editor = "user multiple"
            Tooltip = "Select one or multiple user from user manager"
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


if ($contentTreeListSelector.length -ge 1) {
    $startNodeId = $contentTreeListSelector | ForEach-Object { $_.ID }
}
else {
    Write-Host "No content node selected. Exiting script." -ForegroundColor Red
    return
}

$excludeTemplates = @()

if ($null -ne $radioSelector) {
    if ($radioSelector) {
        $includeNested = $true
    }
}

if ($treeListSelector.length -ge 1) {
    $excludeTemplates = $treeListSelector | ForEach-Object { $_.ID }
}

if ($startDateSelector -ne [System.DateTime]::MinValue -and $endDateSelector -ne [System.DateTime]::MinValue) {
    $startDate = $startDateSelector
    $endDate = $endDateSelector
}

if ($userSelector.length -ge 1) {
   $users =$userSelector
} else {
    Write-Host "No user(s) selected."
}

function Get-ModifiedItems {
    param(
        [string]$ItemPath,
        [bool]$IncludeNested,
        [array]$ExcludeTemplates
    )

    try {
        if (![string]::IsNullOrEmpty($ItemPath)) {           
            if ( $IncludeNested ) {
                $parent = Get-Item -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId } | Where-Object { $users -contains $_."__Updated by" } | Where-Object { ($_.__Updated).Date -ge $startDate -and ($_.__Updated).Date -lt $endDate } 
                $parent
                Export-Item -path master:$ItemPath
                $children = Get-ChildItem -Path "master:$ItemPath" -Recurse | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId } | Where-Object { $users -contains $_."__Updated by" } | Where-Object { ($_.__Updated).Date -ge $startDate -and ($_.__Updated).Date -lt $endDate } 
                foreach ($child in $children) {
                    $child
                    $path = $child.Paths.FullPath
                    Export-Item -path master:$path    
                }
                        
            }
            else {
                $item = Get-Item -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId } | Where-Object { $users -contains $_."__Updated by" } | Where-Object { ($_.__Updated).Date -ge $startDate -and ($_.__Updated).Date -lt $endDate } 
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

$startItem = Get-Item -Path "master:" -ID $startNodeId
$itempath = $startItem.Paths.FullPath
$result = Get-ModifiedItems -ItemPath $itemPath -IncludeNested $includeNested -ExcludeTemplates $excludeTemplates |  Where-Object { $_ -ne "True" -and $_ -ne "False" }



#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 
 
if ($null -eq $result -or $result.Count -eq 0) {
    Show-Alert "There are no modified items under $($itemPath) between start date $($startDate) and end date $($endDate)."
}
else {
    $message = "Total modified items under $($itemPath): $($result.Count)  between start date $($startDate) and end date $($endDate). Serialize data is present into serialization folder."
    Write-Host $message -ForegroundColor Green
    $props = @{
        InfoTitle       = $PSScript.Name
        InfoDescription = "Lists all items that are modified.$($message)"
        PageSize        = 25
        Title           = $PSScript.Name
    }
    
    $result |
    Show-ListView @props -Property @{Label = "Name"; Expression = { $_.DisplayName } },
    @{Label = "Path"; Expression = { $_.ItemPath } },
    @{Label = "ItemID"; Expression = { $_.Id } },
    @{Label = "Updated"; Expression = { $_.__Updated } },
    @{Label = "Updated by"; Expression = { $_."__Updated by" } },
    @{Label = "Created"; Expression = { $_.__Created } },
    @{Label = "Created by"; Expression = { $_."__Created by" } }
}
Close-Window