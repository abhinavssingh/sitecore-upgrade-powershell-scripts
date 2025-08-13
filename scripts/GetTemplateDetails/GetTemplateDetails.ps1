<#
    .SYNOPSIS
        Gets the tempalte details.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

$templateNodeId
$templateId = "{AB86861A-6030-46C5-B394-E8F99E8B87DB}" # Template ID for Sitecore standard Template
$sectionTemplateId = "{E269FBB5-3750-427A-9149-7AA950B49301}" # Template ID for Sitecore Section
$fieldTemplateId = "{455A3E98-A627-4B40-8035-E683A0331AC7}" # Template ID for Sitecore fields

$radioOptions = [ordered]@{
	"Template Details"       = 1
	"Section Details"        = 2
	"Field Details"          = 3
	"Nested Childrens Count" = 4
}

$dialogParams = @{
	Title            = "Get Template Details"
	Description      = "This script retrieves details of templates, sections, and fields from the Sitecore master database. It can also count nested children if enabled."
	OkButtonName     = "Execute"
	CancelButtonName = "Close"
	ShowHints        = $true
    
	Parameters       = @(
		@{
			Name    = "radioSelector"
			Title   = "Select Details Type"
			Editor  = "radio"
			Options = $radioOptions
			Tooltip = "Choose the type of details to retrieve."
		}
		@{
			Name    = "treeListSelector"
			Title   = "Template Selection"
			Editor  = "treelist"
			Source  = "DataSource=/sitecore/templates/Project&DatabaseName=master"
			Tooltip = "Select one more from list"
		}
	)
}
 
$dialogResult = Read-Variable @dialogParams

if ($dialogResult -ne "ok") {
    Write-Host "Script execution cancelled." -ForegroundColor Yellow
    Exit
}

if ($treeListSelector.length -ge 1) {
	$templateNodeId = $treeListSelector | ForEach-Object { $_.ID }
}


function Get-TemplateDetails {
	param (

		[string]$itempath
	)

	try {

		if (-not $itempath) {
			Write-Host "No item path provided. Exiting script." -ForegroundColor Red
			return
		}

		if ($radioSelector -eq 1) {
			$templateItems = Get-ChildItem -Path "master:$itempath" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.TemplateID -eq $templateId }
			foreach ($tItem in $templateItems) {
				$tItem
			}
			
		}
		elseif ($radioSelector -eq 2) {
			$sectionItems = Get-ChildItem -Path "master:$itempath" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.TemplateID -eq $sectionTemplateId }
			foreach ($sItem in $sectionItems) {
				$sItem
			}
		}
		elseif ($radioSelector -eq 3) {
			$fieldItems = Get-ChildItem -Path "master:$itempath" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.TemplateID -eq $fieldTemplateId }
			foreach ($fItem in $fieldItems) {
				$fItem
			}
		}
		elseif ($radioSelector -eq 4) {
			$childrens = Get-ChildItem -Path "master:$itempath" -Recurse -ErrorAction SilentlyContinue
			foreach ($child in $childrens) {
				$child
			}
	
		}
		else {
			Write-Host "Invalid selection. Exiting script." -ForegroundColor Red
			return
		}
		
	}
	catch {
		Write-Error "An error occurred while retrieving template details: $_"
		return
	}

	
}

$item = Get-Item -Path "master:" -ID $templateNodeId -ErrorAction SilentlyContinue
$itemPath = $item.Paths.FullPath
$result = Get-TemplateDetails -itempath $itemPath

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
		$CurrentTime.hours,
		$CurrentTime.minutes,
		$CurrentTime.seconds)) -NoNewline
Start-Sleep 1 

if ($null -eq $result -or $result.Count -eq 0) {
	Show-Alert "No details found under $($itemPath)."
}
else {

	if ($radioSelector -eq 1) {
		$message = "Total temaplates found under $($itemPath): $($result.Count)."
		Write-Host $message -ForegroundColor Green
		$props = @{
			InfoTitle       = $PSScript.Name
			InfoDescription = "Lists all temapltes.$($message)"
			PageSize        = 25
			Title           = $PSScript.Name
		}
    
		$result |
		Show-ListView @props -Property @{Label = " Template Name"; Expression = { $_.Name } },
		@{Label = "Path"; Expression = { $_.ItemPath } },
		@{Label = "Template ID"; Expression = { $_.Id } }
	}
	elseif ($radioSelector -eq 2) {
		$message = "Total sections found under $($itemPath): $($result.Count)."
		Write-Host $message -ForegroundColor Green
		$props = @{
			InfoTitle       = $PSScript.Name
			InfoDescription = "Lists all sections.$($message)"
			PageSize        = 25
			Title           = $PSScript.Name
		}
    
		$result |
		Show-ListView @props -Property @{Label = " Sections Name"; Expression = { $_.Name } },
		@{Label = "Path"; Expression = { $_.ItemPath } },
		@{Label = "Section ID"; Expression = { $_.Id } },
		@{Label = "Template Name"; Expression = { $_.Parent.Name } }
	}
	elseif ($radioSelector -eq 3) {
		$message = "Total field found under $($itemPath): $($result.Count)."
		Write-Host $message -ForegroundColor Green
		$props = @{
			InfoTitle       = $PSScript.Name
			InfoDescription = "Lists all fields.$($message)"
			PageSize        = 25
			Title           = $PSScript.Name
		}
    
		$result |
		Show-ListView @props -Property @{Label = " Field Name"; Expression = { $_.Name } },
		@{Label = "Path"; Expression = { $_.ItemPath } },
		@{Label = "Field ID"; Expression = { $_.Id } },
		@{Label = "Field Type"; Expression = { $_.Type } },
		@{Label = "Section Name"; Expression = { $_.Parent.Name } },
		@{Label = "Template Name"; Expression = { $_.Parent.Parent.Name } }
	}
	elseif ($radioSelector -eq 4) {
		$message = "Total childrens under $($itemPath): $($result.Count)"
		Write-Host $message -ForegroundColor Green
		Show-Alert $message
	}
	
}
Close-Window