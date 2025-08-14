<#
    .SYNOPSIS
        compare and update sitecore items using sitecore item service between two enviornments.
    
    .NOTES
        Abhinav Singh
#>

$Time = [System.Diagnostics.Stopwatch]::StartNew()

# Requires Newtonsoft.Json.Linq

Add-Type -AssemblyName Newtonsoft.Json

# creating variables
$webClient = New-Object System.Net.WebClient
$webClient.Encoding = [System.Text.Encoding]::UTF8
$srcHostName = ""
$targetSitecoreInstance = ""
$baseUrl = "{0}/sitecore/api/ssc/item/?path={1}&database=master&language={2}"
$includeNested = $false # default value for nested children
$startNodeId
# Create a hashtable to store the extracted data, where the key is a combination of item ID and language
$data = @{}

$radioOptions = [ordered]@{
    "Include Nested Children" = 1
}

$dialogParams = @{
    Title            = "Compare Sitecore Items"
    Description      = "This script compares Sitecore items between two environments using the Sitecore Item Service. It allows you to select a content node and optionally include nested children in the comparison. You can also specify templates to exclude from the comparison."
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
            Name    = "srcTextField"
            Title   = "Source Sitecore Instance"
            Tooltip = "Enter the hostname of the source Sitecore instance (e.g., https://source-instance.com)"
        }
        @{
            Name    = "targetTextField"
            Title   = "Target Sitecore Instance"
            Tooltip = "Enter the hostname of the Target Sitecore instance (e.g., https://source-instance.com)"
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

if (![string]::IsNullOrEmpty($srcTextField) -and ![string]::IsNullOrEmpty($targetTextField)) {
    $srcHostName = $srcTextField
    $targetSitecoreInstance = $targetTextField
}
else {
    Write-Host "Source Sitecore instance hostname is required. Exiting script." -ForegroundColor Red
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

function Compare-JsonObjectsAndIdentifyDifferences {
    param(
        [Newtonsoft.Json.Linq.JObject]$Json1,
        [Newtonsoft.Json.Linq.JObject]$Json2,
        [Sitecore.Data.Items.Item]$Item,
        [string]$Language
    )

    $differences = @()

    if ($null -eq $Json1 -and $null -eq $Json2) {
        return $differences # Both null, considered equal
    }

    if ($null -eq $Json1 -or $null -eq $Json2) {
        $differences += "One object is null, the other is not."
        $itemId = $Item.Id
        $key2 = "$itemId-$Language"
        if ($null -eq $Json2) {
            $itemData6 = New-Object PSObject -Property @{
                "ItemName"     = $Item.DisplayName
                "ItemID"       = $Item.id
                "ItemPath"     = $Item.Paths.FullPath
                "ItemLanguage" = $Language
                "PropertyName" = ""
                "OldValue"     = ""
                "NewValue"     = ""
                "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath), is missing in target environment."
            }
            # Add the data to the hashtable with the composite key
            $data[$key2] = $itemData6
        }
        else {
            $itemData7 = New-Object PSObject -Property @{
                "ItemName"     = $Item.DisplayName
                "ItemID"       = $Item.id
                "ItemPath"     = $Item.Paths.FullPath
                "ItemLanguage" = $Language
                "PropertyName" = ""
                "OldValue"     = ""
                "NewValue"     = ""
                "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath), is missing in source environment."
            }
            # Add the data to the hashtable with the composite key
            $data[$key2] = $itemData7
        }

        return $differences # One is null, the other is not
    }

    $properties1 = $Json1.Properties()
    $properties2 = $Json2.Properties()

    #Check for different number of properties.
    <#
    if ($properties1.Count -ne $properties2.Count) {
        $differences += "Objects have different number of properties."
    }
        #>

    foreach ($prop1 in $properties1) {
        $prop2 = $Json2.Property($prop1.Name)
        # Create a unique key using the item ID and language
        $itemId = $Item.Id
        $propertyName = $prop1.Name
        $key = "$itemId-$Language-$propertyName"

        if ($null -eq $prop2) {
            if (!$prop1.Name.Contains("CloneSource")) {
                $differences += "Property '$($prop1.Name)' missing in Json2."
                $itemData1 = New-Object PSObject -Property @{
                    "ItemName"     = $Item.DisplayName
                    "ItemID"       = $Item.id
                    "ItemPath"     = $Item.Paths.FullPath
                    "ItemLanguage" = $Language
                    "PropertyName" = $propertyName
                    "OldValue"     = ""
                    "NewValue"     = ""
                    "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath),Property '$($prop1.Name)' is missing in target environment."
                }
                # Add the data to the hashtable with the composite key
                $data[$key] = $itemData1
            }
           
        }
        else {
            $value1 = $prop1.Value
            $value2 = $prop2.Value

            if ($value1.Type -ne $value2.Type) {
                $differences += "Property '$($prop1.Name)' has different types: '$($value1.Type)' vs '$($value2.Type)'."
                $itemData2 = New-Object PSObject -Property @{
                    "ItemName"     = $Item.DisplayName
                    "ItemID"       = $Item.id
                    "ItemPath"     = $Item.Paths.FullPath
                    "ItemLanguage" = $Language
                    "PropertyName" = $propertyName
                    "OldValue"     = ""
                    "NewValue"     = ""
                    "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath),Property '$($prop1.Name)' has different types: source field type '$($value1.Type)' vs target field type '$($value2.Type)'."
                }
                # Add the data to the hashtable with the composite key
                $data[$key] = $itemData2
            }
            elseif ($value1.Type -eq "Object") {
                $nestedDifferences = Compare-JsonObjectsAndIdentifyDifferences -Json1 ([Newtonsoft.Json.Linq.JObject]$value1) -Json2 ([Newtonsoft.Json.Linq.JObject]$value2) -Item $Item -Language $Language
                if ($nestedDifferences.Count -gt 0) {
                    $differences += "Property '$($prop1.Name)' has nested differences: $nestedDifferences"
                    $itemData3 = New-Object PSObject -Property @{
                        "ItemName"     = $Item.DisplayName
                        "ItemID"       = $Item.id
                        "ItemPath"     = $Item.Paths.FullPath
                        "ItemLanguage" = $Language
                        "PropertyName" = $propertyName
                        "OldValue"     = ""
                        "NewValue"     = ""
                        "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath),Property '$($prop1.Name)' has nested differences: $nestedDifferences."
                    }
                    # Add the data to the hashtable with the composite key
                    $data[$key] = $itemData3
                }
            }
            elseif ($value1.Type -eq "Array") {
                $arrayDifferences = Compare-JsonArraysAndIdentifyDifferences -JsonArray1 ([Newtonsoft.Json.Linq.JArray]$value1) -JsonArray2 ([Newtonsoft.Json.Linq.JArray]$value2) - LItem $Item -Language $Language
                if ($arrayDifferences.Count -gt 0) {
                    $differences += "Property '$($prop1.Name)' has array differences: $arrayDifferences"
                    $itemData4 = New-Object PSObject -Property @{
                        "ItemName"     = $Item.DisplayName
                        "ItemID"       = $Item.id
                        "ItemPath"     = $Item.Paths.FullPath
                        "ItemLanguage" = $Language
                        "PropertyName" = $propertyName
                        "OldValue"     = ""
                        "NewValue"     = ""
                        "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath),Property '$($prop1.Name)' has array differences: $arrayDifferences."
                    }
                    # Add the data to the hashtable with the composite key
                    $data[$key] = $itemData4
                }
            }
            elseif ($value1 -ne $value2) {
                $differences += "Property $($prop1.Name) values differ: $($value1.Value) vs $($value2.Value)"
                if ($propertyName -ne "ItemIcon" -and $propertyName -ne "ItemMedialUrl" -and $propertyName -ne "ItemUrl" -and $propertyName -ne "HasChildren" -and $propertyName -ne "ItemID" -and $propertyName -ne "ParentID" -and $propertyName -ne "TemplateName" -and $propertyName -ne "DisplayName" -and $propertyName -ne "ItemName" -and $propertyName -ne "TemplateID" -and $propertyName -ne "ItemVersion") {
                    if ($null -ne $Item) {
                        $oldValue = $item[$prop1.Name]
                        $Item.Editing.BeginEdit()
                        $Item[$prop1.Name] = $value2.Value
                        $Item.Editing.EndEdit()
                        $itemData = New-Object PSObject -Property @{
                            "ItemName"     = $Item.DisplayName
                            "ItemID"       = $Item.id
                            "ItemPath"     = $Item.Paths.FullPath
                            "ItemLanguage" = $Language
                            "PropertyName" = $propertyName
                            "OldValue"     = $oldValue
                            "NewValue"     = $value2.Value
                            "Remarks"      = ""
                        }
                        # Add the data to the hashtable with the composite key
                        $data[$key] = $itemData
                        Write-Host "Property of Item- $($Item.Name), $($prop1.Name) values updated to $($value2.Value)"
                    }
                }
            }
        }
    }

    #check for properties that exist in json2, but not json1.
    foreach ($prop2 in $properties2) {
        $prop1 = $Json1.Property($prop2.Name)
        $itemId = $Item.Id
        $propertyName1 = $prop2.Name
        $key1 = "$itemId-$Language-$propertyName1"
        if ($null -eq $prop1) {
            if (!$prop2.Name.Contains("CloneSource")) {
                $differences += "Property '$($prop2.Name)' missing in Json1."
                $itemData5 = New-Object PSObject -Property @{
                    "ItemName"     = $Item.DisplayName
                    "ItemID"       = $Item.id
                    "ItemPath"     = $Item.Paths.FullPath
                    "ItemLanguage" = $Language
                    "PropertyName" = $prop2.Name
                    "OldValue"     = ""
                    "NewValue"     = ""
                    "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath),Property '$($prop2.Name)' is missing in source environment."
                }
                # Add the data to the hashtable with the composite key
                $data[$key1] = $itemData5
            }
            
        }
    }

    return $differences
}

function Compare-JsonArraysAndIdentifyDifferences {
    param(
        [Newtonsoft.Json.Linq.JArray]$JsonArray1,
        [Newtonsoft.Json.Linq.JArray]$JsonArray2,
        [Sitecore.Data.Items.Item]$LItem,
        [string]$Language
    )

    $differences = @()

    if ($JsonArray1.Count -ne $JsonArray2.Count) {
        $differences += "Arrays have different lengths."
        return $differences
    }

    for ($i = 0; $i -lt $JsonArray1.Count; $i++) {
        $item1 = $JsonArray1[$i]
        $item2 = $JsonArray2[$i]
		

        if ($item1.Type -eq "Object" -and $item2.Type -eq "Object") {
            $itemDifferences = Compare-JsonObjectsAndIdentifyDifferences -Json1 ([Newtonsoft.Json.Linq.JObject]$item1) -Json2 ([Newtonsoft.Json.Linq.JObject]$item2) -Item $LItem -Language $Language
            if ($itemDifferences.Count -gt 0) {
                $differences += "Difference at index $i $itemDifferences"
            }
        }
        elseif ($item1.Type -eq "Array") {
            $itemDifferences = Compare-JsonArraysAndIdentifyDifferences -JsonArray1 ([Newtonsoft.Json.Linq.JArray]$item1) -JsonArray2 ([Newtonsoft.Json.Linq.JArray]$item2) -Item $LItem -Language $Language
            if ($itemDifferences.Count -gt 0) {
                $differences += "Difference at index $i $itemDifferences"
            }
        }
        elseif ($item1 -ne $item2) {
            $differences += "Difference at index $i '$item1' vs '$item2'"
        }
    }

    return $differences
}

function ItemCompare {
    param (
        [Parameter(Mandatory = $true)]
        [Sitecore.Data.Items.Item]$Item
    )
    try {
        if ($null -ne $Item) {
            $languages = $Item.Languages
            foreach ($language in $languages) {
                $langItem = Get-Item -Path master: -ID $Item.Id -language $language | Where-Object { $_.Versions.GetVersions($true).Count -gt 0 }
                if ($null -ne $langItem) {
                    # Compare two JSON responses
                    $path = $langItem.Paths.FullPath
                    $sUrl = $baseUrl -f $srcHostName, $path, $language.Name
                    Write-Host $sUrl
                    $sResponse = $webClient.DownloadString($sUrl)
                    $dUrl = $baseUrl -f $targetSitecoreInstance, $path, $language.Name
                    Write-Host $dUrl
                    $dResponse = $webClient.DownloadString($dUrl)
                    if ($null -ne $sResponse -and $null -ne $dResponse) {
                        $jsonObject1 = [Newtonsoft.Json.Linq.JObject]::Parse($sResponse)
                        $jsonObject2 = [Newtonsoft.Json.Linq.JObject]::Parse($dResponse)
                        Compare-JsonObjectsAndIdentifyDifferences -Json1 $jsonObject1 -Json2 $jsonObject2 -Item $Item -Language $language.Name
                    }
                }
                else {
                    Write-Host "Item $($langItem) not found in language: $($language.Name)" -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Host "Item not found: $($Item.Name)" -ForegroundColor Red
            return
        }
    }
    catch [System.Net.WebException] {
        $key3 = "$($Item.Id)-$($Language)"
        if ($null -ne $sResponse) {
            $itemData8 = New-Object PSObject -Property @{
                "ItemName"     = $Item.DisplayName
                "ItemID"       = $Item.id
                "ItemPath"     = $Item.Paths.FullPath
                "ItemLanguage" = $Language
                "PropertyName" = ""
                "OldValue"     = ""
                "NewValue"     = ""
                "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath), is missing in target environment."
            }
            # Add the data to the hashtable with the composite key
            $data[$key3] = $itemData8 
        }
        if ($null -ne $dResponse) {
            $itemData9 = New-Object PSObject -Property @{
                "ItemName"     = $Item.DisplayName
                "ItemID"       = $Item.id
                "ItemPath"     = $Item.Paths.FullPath
                "ItemLanguage" = $Language
                "PropertyName" = ""
                "OldValue"     = ""
                "NewValue"     = ""
                "Remarks"      = "$($Item.ID), $($Item.Paths.FullPath), is missing in source environment."
            }
            # Add the data to the hashtable with the composite key
            $data[$key3] = $itemData9 
        }
        return
    }
    catch [Newtonsoft.Json.JsonReaderException] {
        Write-Error "JSON parsing error occurred while processing item: $($Item.Name) - $_"
        return
    }
    catch {
        Write-Error "An error occurred while processing item: $($Item.Name) - $_"
        return
    }
}
function Compare-SitecoreItems {
    param (
        [string]$ItemPath,
        [bool]$IncludeNested,
        [array]$ExcludeTemplates
    )
    
    try {
        if (![string]::IsNullOrEmpty($ItemPath)) {
            if ($IncludeNested) {
                $parentItem = Get-Item -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId }
                ItemCompare -Item $parentItem
                $childrens = Get-ChildItem -Path "master:$ItemPath" -Recurse | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId } 
                foreach ($child in $childrens) {
                    ItemCompare -Item $child
                }
            }
            else {
                $item = Get-Item -Path "master:$ItemPath" | Where-Object { $ExcludeTemplates -notcontains $_.TemplateId } 
                ItemCompare -Item $item
            }
        }
        else {
            Write-Host "Item path is empty. Please provide a valid item path." -ForegroundColor Red
            return
        }
    }
    catch {
        Write-Error "An error occurred while comparing items: $_"
    }
}

$startItem = Get-Item -Path "master:" -ID $startNodeId
$itempath = $startItem.Paths.FullPath
Compare-SitecoreItems -ItemPath $itempath -IncludeNested $includeNested -ExcludeTemplates $excludeTemplates

#Elapsed time
$Time.Stop()
$CurrentTime = $Time.Elapsed
Write-Host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
        $CurrentTime.hours,
        $CurrentTime.minutes,
        $CurrentTime.seconds)) -NoNewline
Start-Sleep 1 

if ($data.Count -eq 0) {
    Write-Host "No differences found." -ForegroundColor Green
}
else {
    $data.Values | Show-ListView -Title $PSScript.Name -InfoDescription "Total diffreneces between source vs targent environment: $($data.Count)" -PageSize 25
} 