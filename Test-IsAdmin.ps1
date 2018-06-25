<#
.SYNOPSIS
    Tests if a user is a local admin on the machine
    
.DESCRIPTION
    Note only returns true for directly added users, if 
    user is added via a group, will return false
    
    spence@harbar.net
    25/06/2015
    
.NOTES
	File Name  : Test-IsAdmin.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file

#>


#region PARAMS
param (  
    [String]$User
    ) 
#endregion PARAMS



#region MAIN
try {
    $IsAdmin = $false
    $LocalAdmins = net localgroup administrators |  Where-Object {$_ -AND $_ -notmatch "command completed successfully"} | Select-Object -skip 4 
    
    foreach ($Admin in $LocalAdmins) {        
        if ( $Admin -eq $User ) {$IsAdmin = $true} 
    }
    return $IsAdmin 
}
catch {
    return $false
}

#endregion MAIN
#EOF