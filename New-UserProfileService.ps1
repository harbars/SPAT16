<#
.SYNOPSIS
    Creates New UPA avoiding Default Schema Issue

.DESCRIPTION

    Still important despite removal of UPS in SP 2016+
      
    spence@harbar.net
    25/06/2015
    
.NOTES
	File Name  : New-UserProfileService.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file

#>

#region PARAMS
param (  
    [String]$Server,
    [String]$SaAppPoolName,
    [String]$UpaName,
    [String]$UpaProfileDBName,
    [String]$UpaSocialDBName,
    [String]$UpaSyncDBName,
    [String]$MySiteHost
) 
#endregion PARAMS


#region MAIN
try {
    If ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -EA 0) -eq $null) { Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" }

    <# Creates UPA Service Application & Proxy, and User Profile Service Instance
         If omitted, -ProfileSyncDBServer, -SocialDBServer & -ProfileDBServer are the SharePoint Default DB Server
         If omitted, -SyncInstanceMachine is the local machine 
    #>
    Write-Host "$(Get-Date -Format T) : Creating $UpaName Application & Proxy..."
    $Upa = New-SPProfileServiceApplication -Name $UpaName -ApplicationPool $SaAppPoolName `
                                           -ProfileDBName $UpaProfileDBName -SocialDBName $UpaSocialDBName `
                                           -ProfileSyncDBName $UpaSyncDBName -MySiteHostLocation $MySiteHost
    $UpaProxy = New-SPProfileServiceApplicationProxy -Name "$UpaName Proxy" -ServiceApplication $Upa -DefaultProxyGroup

    Write-Host "$(Get-Date -Format T) : Created $UpaName Application & Proxy!" -ForegroundColor Green
}
catch {
    Write-Host "OOOPS! We failed during creating UPA on $server." -ForegroundColor Red
    $_
    Exit
}

#endregion MAIN
#EOF