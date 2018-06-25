<#
.SYNOPSIS
    Adds a new Shell Admin
    

.DESCRIPTION

    
      

    spence@harbar.net
    15/03/2016
    



.NOTES
	File Name  : New-ShellAdmin.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file

#>


#region PARAMS
param (  
    [String]$server,
    [String]$user,
    [String]$usageDbName,
    [String]$searchDbName
) 
#endregion PARAMS



#region MAIN
try {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
    $dbs = Get-SPDatabase | Where-Object {$_.Name -notlike "$searchDbName*" -and $_.Name -ne $usageDbName}
    $dbs | Add-SPShellAdmin -UserName $user
}
catch {
    Write-Host "OOOPS! We barfed during adding Shell Admin on $server." -ForegroundColor Red
    $_
    Exit
}

#endregion MAIN
#EOF