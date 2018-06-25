<#
.SYNOPSIS
    Sets the Distributed Cache Service Identity
    
.DESCRIPTION

    Used as part of 2013 topology builder
    
    spence@harbar.net
    25/02/2016
    

.NOTES
	File Name  : Set-DistributedCacheIdentity.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file

#>


#region PARAMS
param (  
    [String]$Server,
    [String]$ServiceManagedAccountName
) 
#endregion PARAMS



#region MAIN
try {
    If ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -EA 0) -eq $null) { Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" }
   
    Write-Host "$(Get-Date -Format T) : Configuring Distributed Cache Service Account..."
    Write-Host "$(Get-Date -Format T) : This normally takes about 8 minutes..." -ForegroundColor Yellow
    $SpFarm = Get-SPFarm
    $ServiceManagedAccount = Get-SPManagedAccount $ServiceManagedAccountName
    $DcService = $Spfarm.Services | Where-Object {$_.Name -eq "AppFabricCachingService"}
    $DcService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
    $DcService.ProcessIdentity.ManagedAccount = $serviceManagedAccount
    $DcService.ProcessIdentity.Update() 
    $DcService.ProcessIdentity.Deploy() # only works when there is a single box in the farm with DC and we are running on it
    Write-Host "$(Get-Date -Format T) : Distributed Cache Service Account Updated!" -ForegroundColor Green
}
catch {
    Write-Host "OOOPS! We failed during configuring Distributed Cache Service Account" -ForegroundColor Red
    $_
    Exit
}

#endregion MAIN
#EOF