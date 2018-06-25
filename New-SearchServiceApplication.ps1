<#
.SYNOPSIS
    Creates a new SharePoint 2016 Search Service Application
    
.DESCRIPTION
    Creates a new SharePoint 2016 Search Service Application

    MUST be run a machine of role Search or Custom (which 
    is running Search and Search Host Controller)
      

    spence@harbar.net
    25/06/2015 - Original work created for MinRole Scenario Testing
    
.NOTES
	File Name  : New-SearchServiceApplication.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file
#>
[CmdletBinding()]

#region PARAMS
param (  
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=0)]
    [ValidateNotNullorEmpty()]
    [String]$SaAppPoolName,

    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=1)]
    [ValidateNotNullorEmpty()]
    [String]$SearchServiceAppName,

    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=2)]
    [ValidateNotNullorEmpty()]
    [String]$SearchAliasName,

    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=3)]
    [ValidateNotNullorEmpty()]
    [String]$SearchDbName
) 
#endregion PARAMS

begin {
    If ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -EA 0) -eq $null) { Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" }
    $Server = $env:COMPUTERNAME
    Write-Output "$(Get-Date -Format T) : Creating $SearchServiceAppName and Proxy on $Server..."
}

process {
    try { 
        
        $ServicesAppPool = Get-SPServiceApplicationPool $SaAppPoolName
        $SearchServiceApp = New-SPEnterpriseSearchServiceApplication -Name $SearchServiceAppName `
                            -ApplicationPool $ServicesAppPool -DatabaseServer $SearchAliasName `
                            -DatabaseName $SearchDbName

        $SearchProxy = New-SPEnterpriseSearchServiceApplicationProxy -Name "$SearchServiceAppName Proxy" `
                       -SearchApplication $SearchServiceApp
 
    }
    catch {
        Write-Host "OOOPS! We failed during creating $SearchServiceAppName and Proxy on $Server." -ForegroundColor Red
        $_
        Exit
    }
}

end {
    Write-Output "$(Get-Date -Format T) : Created $SearchServiceAppName on $Server!"
}
#EOF
