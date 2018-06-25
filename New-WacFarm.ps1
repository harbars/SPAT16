<#
.SYNOPSIS
    Creates a new Office Web Apps (WAC) Farm
    
.DESCRIPTION

    spence@harbar.net
    25/01/2016
    
.NOTES
	File Name  : New-WacFarm.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file
#>


#region PARAMS
param (  
    [String]$server,
    [String]$internalUrl = "https://wac.fabrikam.com",
    [String]$externalUrl = "https://wac.fabrikam.com",
    [String]$certName = "wac.fabrikam.com",
    [String]$cacheLocation = "c:\WACCache\",         
    [String]$logLocation = "c:\WACLog\",       
    [String]$renderCache = "c:\WACRenderCache\",    
    [String]$cacheSize = 15,                             
    [String]$docInfoSize = 5000,                      
    [String]$maxMem = 1024
) 
#endregion PARAMS

#region MAIN
try {
    Import-Module OfficeWebApps
   
    Write-Output "$(Get-Date -Format T) : Creating Office Web Apps Farm on $server..."
    $testURL = "$internalUrl/m/met/participant.svc/jsonAnonymous/BroadcastPing"

    New-OfficeWebAppsFarm `
        -InternalURL $internalurl `
        -ExternalURL $externalurl `
        -OpenFromUrlEnabled `
        -OpenFromUncEnabled `
        -ClipartEnabled `
        -CacheLocation $cachelocation `
        -LogLocation $loglocation `
        -RenderingLocalCacheLocation $rendercache `
        -CacheSizeInGB $cacheSize `
        -DocumentInfoCacheSize $docInfoSize `
        -MaxMemoryCacheSizeInMB $maxMem `
        -CertificateName $certName `
        -EditingEnabled:$false `
        -Confirm:$false | out-null
     
     $ver = (Invoke-WebRequest $testURL -UseBasicParsing).Headers["X-OfficeVersion"]
     Write-Output "$(Get-Date -Format T) : WAC Farm Version: $ver"
}
catch {
    Write-Host "OOOPS! We failed during creation of WAC Farm on $server." -ForegroundColor Red
    $_
    Exit
}

#endregion MAIN
#EOF