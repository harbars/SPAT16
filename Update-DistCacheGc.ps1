# update Distributed Cache Config File to include BackgroundGC
# this is somewhat of a hack, but it works

# read the config file
$dcConfig = "C:\Program Files\AppFabric 1.1 for Windows Server\DistributedCacheService.exe.config"
[xml]$xml = Get-Content ($dcConfig)

# make a backup
[String]$timestamp = (Get-Date -Format 'yyyyMMddhhmmss')
$xml.Save("$dcConfig.$timestamp")

# add appSettings if it doesn't exsit (it won't by default)
$appSettings = $xml.configuration["appSettings"]
if ($appSettings -eq $null)
{
    $appSettings = $xml.CreateElement("appSettings")
    $xml.configuration.AppendChild($appSettings) | Out-Null
    $xml.Save($dcConfig) | out-null
    [xml]$xml = Get-Content ($dcConfig)
}

$keyFound = $false
foreach ($item in $xml.configuration["appSettings"].add) {
    if ($item.Key -eq "backgroundGC") {
        $item.value = "true"
        $keyFound = $true
    }
}


if (!$keyFound) {
    $newEl = $xml.CreateElement("add") 
    $nameAtt1 = $xml.CreateAttribute("key")
    $nameAtt1.Value = "backgroundGC"
    $newEl.SetAttributeNode($nameAtt1) | out-null #suppress
    $nameAtt2 = $xml.CreateAttribute("value")
    $nameAtt2.Value = "true"
    $newEl.SetAttributeNode($nameAtt2) | out-null #suppress
    $xml.configuration["appSettings"].AppendChild($newEl) | out-null #suppress
}
$xml.Save($dcConfig) | Out-Null
Write-Output "$(Get-Date -Format T) : Distributed Cache Config Updated on $env:ComputerName"