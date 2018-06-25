<#
.SYNOPSIS
    Adds host to cache cluster
    

.DESCRIPTION

    Used as part of 2013 topology builder
    Also used when dealing with changing DC service indentity
    
      

    spence@harbar.net
    25/06/2015
    



.NOTES
	File Name  : Add-DistCache.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file

#>


#region PARAMS
param (  
    [String]$server
) 
#endregion PARAMS



#region MAIN
try {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
   
    Write-Host "$(Get-Date -Format T) : Adding server $server as Distributed Cache host..."
    Write-Host "$(Get-Date -Format T) : This normally takes about 2 minutes..." -ForegroundColor Yellow
    Add-SPDistributedCacheServiceInstance 
    Write-Host "$(Get-Date -Format T) : Added Distributed Cache host!" -ForegroundColor Green
}
catch {
    Write-Host "OOOPS! We barfed during adding cache host cluster on $server." -ForegroundColor Red
    $_
    Exit
}

#endregion MAIN
#EOF