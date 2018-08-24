<#
.SYNOPSIS
    Creates a new Content Source Start Address
    
.DESCRIPTION
    Creates a new Content Source Start Address

    Used to avoid issue with the "attempted to perform an unauthorised operation" 
    error (which succeeds anyway) when not running this on a machine hosting search
      
    spence@harbar.net
    25/06/2015 - Original work created for MinRole Scenario Testing
    
.NOTES
	File Name  : New-StartAddress.ps1
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
    [String]$SearchServiceAppName,

    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=2)]
    [ValidateNotNullorEmpty()]
    [String]$ProfileStartAddress
) 
#endregion PARAMS

begin {
    If ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -EA 0) -eq $null) { Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" }
    $Server = $env:COMPUTERNAME
    Write-Output "$(Get-Date -Format T) : Creating $ProfileStartAddress on $Server..."
}

process {
    try { 
        $SearchServiceApp = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceAppName
        $contentSource = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $SearchServiceApp

        If ($contentSource.StartAddresses | Where-Object {$_.OriginalString -eq $ProfileStartAddress})
        {
            Write-Output "$(Get-Date -Format T) : Start Adress $ProfileStartAddress already exists!"
        }
        Else
        {
            $ContentSource.StartAddresses.Add($ProfileStartAddress)  #MUST RUN ON SEARCH BOX TO AVOID ERROR
            $ContentSource.Update()
        }
    }
    catch {
        Write-Host "OOOPS! We failed during creating $ProfileStartAddress on $Server." -ForegroundColor Red
        $_
        Exit
    }
}

end {
    Write-Output "$(Get-Date -Format T) : Created $ProfileStartAddress on $Server!"
}
#EOF