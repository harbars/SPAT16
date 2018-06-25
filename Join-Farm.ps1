<#
.SYNOPSIS
    Joins a machine to a SharePoint Farm.
    
.DESCRIPTION
    spence@harbar.net
    25/06/2015

    12/01/2016: updates for 2013 farm support
    
.NOTES
	File Name  : Join-Farm.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file

#>


#region PARAMS
param (  
    [String]$Server,
    [String]$DatabaseServer,
    [String]$ConfigDatabase,
    [SecureString]$Passphrase,
    [String]$ServerRole,
    [bool]$ServerRoleOptional
) 
#endregion PARAMS



#region MAIN
try {
    If ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -EA 0) -eq $null) { Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" }
   
    Write-Output "$(Get-Date -Format T) : Joining server $Server to the farm as $ServerRole..."
    if ($ServerRoleOptional) {
        Connect-SPConfigurationDatabase -DatabaseName $ConfigDatabase `
                                        -DatabaseServer $DatabaseServer `
                                        -Passphrase $Passphrase `
                                        -SkipRegisterAsDistributedCacheHost
    }
    else {
        Connect-SPConfigurationDatabase -DatabaseName $ConfigDatabase `
                                        -DatabaseServer $DatabaseServer `
                                        -Passphrase $Passphrase `
                                        -LocalServerRole $ServerRole `
                                        -SkipRegisterAsDistributedCacheHost
    }
   
    Write-Output "$(Get-Date -Format T) : Installing Help..."
    Install-SPHelpCollection -All
    Write-Output "$(Get-Date -Format T) : ACLing SharePoint Resources..."
    Initialize-SPResourceSecurity
    Write-Output "$(Get-Date -Format T) : Installing Services..."
    Install-SPService | Out-Null
    Write-Output "$(Get-Date -Format T) : Installing Features..."
    Install-SPFeature -AllExistingFeatures | Out-Null
    # if role is Search then don't install app content as the Content Service isn't present
    if ($ServerRole -ne "Search") {
        Write-Output "$(Get-Date -Format T) : Installing Application Content..."
        Install-SPApplicationContent
    }
    Write-Output "$(Get-Date -Format T) : Server $Server joined to the farm!"
    Write-Output "$(Get-Date -Format T) : Restarting SharePoint Timer Service..."
    Restart-Service -Name "SPTimerV4"
    Write-Output "$(Get-Date -Format T) : SharePoint Timer Service Restarted!"
}
catch {
    Write-Host "OOOPS! We failed during Farm Join on $server." -ForegroundColor Red
    $_
    Exit
}

#endregion MAIN
#EOF