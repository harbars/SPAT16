# Configure-CrlBypass.ps1  
# modified by spence to check presence of each framework v2 (not instaled on WAC)
# and general tidy up to fit model of SPAT


#region PARAMS
param () 
#endregion PARAMS

# paths
$netV232path = "c:\Windows\Microsoft.NET\Framework\v2.0.50727\CONFIG\machine.config"
$netV264path = "c:\Windows\Microsoft.NET\Framework64\v2.0.50727\CONFIG\machine.config"
$netV432path = "c:\Windows\Microsoft.NET\Framework\v4.0.30319\CONFIG\machine.config"
$netV464path = "c:\Windows\Microsoft.NET\Framework64\v4.0.30319\CONFIG\machine.config"


#v2 32 bit
$path = $netV232path
if (Test-Path $path) {
    $xml = [xml](get-content($path))
    $xml.Save($path+ ".old")
    $runtime = $xml.configuration["runtime"]

    if($runtime.generatePublisherEvidence -eq $null) {
        Write-Host "$(Get-Date -Format T) : .NET v2 32bit creating generatePublisherEvidence - setting false on $env:ComputerName"
        $GPE = $xml.CreateElement("generatePublisherEvidence")
        $GPE.SetAttribute("enable", "false")
        $runtime.AppendChild($GPE)
    }
    else {
        Write-Host "$(Get-Date -Format T) : .NET v2 32bit detected generatePublisherEvidence - setting false on $env:ComputerName"
        $runtime.generatePublisherEvidence.enable = "false";
    }
    $xml.Save($path)
}

#v4 32 bit
$path = $netV432path
if (Test-Path $path) {
    $xml = [xml](get-content($path))
    $xml.Save($path+ ".old")
    $runtime = $xml.configuration["runtime"]

    if($runtime.generatePublisherEvidence -eq $null) {
        Write-Host "$(Get-Date -Format T) : .NET v4 32bit creating generatePublisherEvidence - setting false on $env:ComputerName"
        $GPE = $xml.CreateElement("generatePublisherEvidence")
        $GPE.SetAttribute("enable", "false")
        $runtime.AppendChild($GPE)
    }
    else {
        Write-Host "$(Get-Date -Format T) : .NET v4 32bit detected generatePublisherEvidence - setting false on $env:ComputerName"
        $runtime.generatePublisherEvidence.enable = "false";
    }
    $xml.Save($path)
}



#Set 64bit V2 Framework
$path = $netV264path
if (Test-Path $path) {
    $xml = [xml](get-content($path))
    $xml.Save($path+ ".old")
    $runtime = $xml.configuration["runtime"]

    if($runtime.generatePublisherEvidence -eq $null) {
        Write-Host "$(Get-Date -Format T) : .NET v2 64bit creating generatePublisherEvidence - setting false on $env:ComputerName"
        $GPE = $xml.CreateElement("generatePublisherEvidence")
        $GPE.SetAttribute("enable", "false")
        $runtime.AppendChild($GPE)
    }
    else {
        Write-Host "$(Get-Date -Format T) : .NET v2 64bit detected generatePublisherEvidence - setting false on $env:ComputerName"
        $runtime.generatePublisherEvidence.enable = "false";
    }
    $xml.Save($path)
}


#Set 64bit V4 Framework
$path = $netV464path
if (Test-Path $path) {
    $xml = [xml](get-content($path))
    $xml.Save($path+ ".old")
    $runtime = $xml.configuration["runtime"]

    if($runtime.generatePublisherEvidence -eq $null) {
        Write-Host "$(Get-Date -Format T) : .NET v4 64bit creating generatePublisherEvidence - setting false on $env:ComputerName"
        $GPE = $xml.CreateElement("generatePublisherEvidence")
        $GPE.SetAttribute("enable", "false")
        $runtime.AppendChild($GPE)
    }
    else {
        Write-Host "$(Get-Date -Format T) : .NET v4 64bit detected generatePublisherEvidence - setting false on $env:ComputerName"
        $runtime.generatePublisherEvidence.enable = "false";
    }
    $xml.Save($path)
}


#EOF