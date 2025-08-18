<#
    .SYNOPSIS
        Delete items through csv file.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Execution Started"

# Create a hashtable to store the extracted data, where the key is a combination of item ID and language
$data = @{}
function GetHostName {
	$contentItemId = "{0DE95AE4-41AB-4D01-9EB0-67441B7C2450}"
	$contentItem = Get-Item -Path master: -Id $contentItemId
	$urlOptions = New-Object Sitecore.Links.UrlOptions
	$urlOptions.AlwaysIncludeServerUrl = $true;
	$pageUrl = [Sitecore.Links.LinkManager]::GetItemUrl($contentItem, $urlOptions);
	$stringArray = $pageUrl.split("/")
	return $stringArray[2]
}

# write output file
$hostName = GetHostName
$webRootPath = Get-Website -Name $hostName | Select-Object -ExpandProperty PhysicalPath

$uploadFile = Show-ModalDialog -HandleParameters @{
	"h" = "FileBrowser";
} -Control "FileBrowser" -Width 500

if ($null -eq $uploadFile) {
	Write-Host "No file selected. Exiting script."
	Close-Window
	return
}

# Define the path to the csv file
$inputFile = $webRootPath + $uploadFile

# Load the csv data into a variable
$csvData = Import-Csv -Path $inputFile

if ($null -eq $csvData) {
	Write-Host "No data found in the CSV file. Exiting script."
	Close-Window
	return
}
else {
	foreach ($row in $csvData) {
		$ItemID = $row.ItemId
		$Item = Get-Item -Path master: -Id $ItemID

		$itemId = $Item.id
		$language = $Item.language
		# Create a unique key using the item ID and language
		$key = "${itemId}_${language}"
		$itemData = New-Object PSObject -Property @{
			"DispalyName" = $Item.DisplayName
			"ID"          = $Item.id
			"Name"        = $Item.Name
			"ItemPath"    = $Item.Paths.FullPath
		}

		# Add the data to the hashtable with the composite key
		$data[$key] = $itemData

		Write-Host "Deleting: " $Item.Name
		$Item | Remove-Item
	}
}



Write-Host "Execution Completed"

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
		$CurrentTime.hours,
		$CurrentTime.minutes,
		$CurrentTime.seconds)) -NoNewline
Start-Sleep 1 

if ($data.Count -eq 0) {
	Show-Alert "no deleted items found."
}
else {
	$data.Values | Show-ListView -Title $PSScript.Name -InfoDescription "`nTotal items deleted: $($data.Count)" -PageSize 25
}

Close-Window