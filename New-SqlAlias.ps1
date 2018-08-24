<#
.SYNOPSIS
    Creates a new SQL Server Alias
    
.DESCRIPTION
    Creates a  SQL Server Alias

    we create the x64 key even thou it's not used by SharePoint. Just in case we need it in the future (e.g. update)
    only creates TCP/IP alias
    DBMSSOCN,FABSQL1,1433
      
    spence@harbar.net
    25/06/2015 - Original work created for MinRole Scenario Testing
    
.NOTES
	File Name  : New-SqlAlias.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file
#>
[CmdletBinding()]

#region PARAMS
param (  
    [String]$aliasName,
    [String]$serverName,
    [String]$instanceName,
    [String]$port
) 
#endregion PARAMS

begin {}
process {
    if ($instanceName -ne "") { 
        $tcpAlias = ("DBMSSOCN,$serverName\$instanceName,$port")
    }
    else {
        $tcpAlias = ("DBMSSOCN,$serverName,$port")
    }
    $clientPath = "HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo"
    $clientX64Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"

    if (!(Test-Path $clientPath)) {
        New-Item $clientPath | Out-Null
    }
    if (!(Test-Path $clientX64Path)) {
        New-Item $clientX64Path | Out-Null
    }

    New-ItemProperty $clientPath -Name $aliasName -PropertyType "String" -Value $tcpAlias -force | Out-Null
    New-ItemProperty $clientX64Path -Name $aliasName -PropertyType "String" -Value $tcpAlias -force | Out-Null
}
end {
    Write-Output "$(Get-Date -Format T) : SQL Alias $aliasName created on $env:ComputerName"
}
#EOF