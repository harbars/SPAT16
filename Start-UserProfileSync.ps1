<#
.SYNOPSIS
    Starts User Profile Synchronization Service Instance
    
.DESCRIPTION

    spence@harbar.net
    25/06/2015

    12/12/2015: updated process to start and check status
    14/02/2016: updated for Atos scripts
    
.NOTES
	File Name  : Start-UserProfileSync.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file

#>

#region PARAMS
param (  
    [String]$Server,
    [String]$UpaName,
    [PSCredential]$FarmAccount
) 
#endregion PARAMS

#region MAIN
try {
    If ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -EA 0) -eq $null) { Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" }
    Write-Host "$(Get-Date -Format T) : Starting the User Profile Synchronization service..."
    Write-Host "$(Get-Date -Format T) : This normally takes about 5 minutes..." -ForegroundColor Yellow

    $UpsInstanceName = "User Profile Synchronization Service"
    $Upa = Get-SPServiceApplication | where-object {$_.Name -eq $UpaName}
    $Ups = Get-SPServiceInstance -Server $Server | where-object {$_.TypeName -eq $UpsInstanceName}
    $Ups.UserProfileApplicationGuid = $Upa.Id
    $Ups.Update()
    
    $Upa.SetSynchronizationMachine($Server, $Ups.Id , $FarmAccount.UserName, $FarmAccount.GetNetworkCredential().Password)
    $Upa.Update()
    
    Start-SPServiceInstance -Identity $Ups | Out-Null
    while((Get-SPServiceInstance -Server $Server | where-object {$_.TypeName -eq $UpsInstanceName}).Status -ne "Online"){
   	    Start-Sleep 60
    }
    Write-Host "$(Get-Date -Format T) : UPS Started!" -ForegroundColor Green
}
catch {
    Write-Host "OOOPS! We failed during starting UPS on $server." -ForegroundColor Red
    $_
    Exit
}
#endregion MAIN
#EOF