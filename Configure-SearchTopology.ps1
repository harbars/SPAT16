<#
.SYNOPSIS
    Configures the SharePoint Search Service Application Topology

.DESCRIPTION

    Expects Search Services to already be running.
    Derived from original MinRole (SP16) utility

    Single Server topology - all roles on one server.
    Collapsed Roles or Custom

    ** Farm MUST have search services running before this script executes **
    ** Handled by MinRole and controller script for 2016 **

    ** THIS SCRIPT MUST BE RUN ON A MACHINE WITH A SEARCH ROLE **
    ** Handled by the controller **


    spence@harbar.net
    17/03/2016: new version for just topology
    


.NOTES
	File Name  : Configure-SearchTopology.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file

#>

#region PARAMS
param (  
    [String]$SearchServiceApplicationName,
    [Bool]$changeIndexLocation = $false,
    [String[]]$searchServers,
    [String[]]$adminQueryIndexServers,
    [String[]]$crawlContentAnalyticsServers,
    [String]$IndexLocationDrive,
    [String]$IndexLocationPath,
    [Bool]$debug = $false
) 
#endregion PARAMS

#region INIT
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -EA 0) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }
if ($debug) {
    Write-Host "We have entered the SSA Topology Script on $env:ComputerName" -ForegroundColor Magenta
    Write-Host "Parameters: " -ForegroundColor Magenta
    Write-Host "=======================================" -ForegroundColor Magenta
    Write-Host "SA Name: $SearchServiceApplicationName" -ForegroundColor Magenta
    Write-Host "=======================================" -ForegroundColor Magenta
    Write-Host "Change Index Location: $changeIndexLocation" -ForegroundColor Magenta
    Write-Host "Search Servers: $searchServers" -ForegroundColor Magenta
    Write-Host "Query Index Admin: $adminQueryIndexServers" -ForegroundColor Magenta
    Write-Host "Crawl Content Analytics: $crawlContentAnalyticsServers" -ForegroundColor Magenta
    Write-Host "Index Drive: $indexLocationDrive" -ForegroundColor Magenta
    Write-Host "Index Path: $indexLocationPath" -ForegroundColor Magenta
    Write-Host "=======================================" -ForegroundColor Magenta
    Pause
}
#endregion INIT

#region FUNCTIONS

#region SEARCH COMPONENT HELPERS

# add a new QUERY PROCESSING component
function New-QueryProcessingComponent ($topology, $instance) {
    if ($debug) {
	    New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $topology -SearchServiceInstance $instance
    }
    else {
        New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $topology -SearchServiceInstance $instance | Out-Null
    }
}

# add a new ADMIN component
function New-AdminComponent ($topology, $instance) {
    if ($debug) {
	    New-SPEnterpriseSearchAdminComponent -SearchTopology $topology -SearchServiceInstance $instance
    }
    else {
        New-SPEnterpriseSearchAdminComponent -SearchTopology $topology -SearchServiceInstance $instance | Out-Null
    }
}

# add a new INDEX component
function New-IndexComponent ($topology, $instance, $indexPartition, $indexLocation) {
    if ($indexLocation -ne "") {
        if ($debug) {
	        New-SPEnterpriseSearchIndexComponent -SearchTopology $topology -SearchServiceInstance $instance -IndexPartition $indexPartition -RootDirectory $indexLocation
        }
        else {
            New-SPEnterpriseSearchIndexComponent -SearchTopology $topology -SearchServiceInstance $instance -IndexPartition $indexPartition -RootDirectory $indexLocation | Out-Null
        }
    }
    else {
        if ($debug) {
            New-SPEnterpriseSearchIndexComponent -SearchTopology $topology -SearchServiceInstance $instance -IndexPartition $indexPartition
        }
        else {
            New-SPEnterpriseSearchIndexComponent -SearchTopology $topology -SearchServiceInstance $instance -IndexPartition $indexPartition | Out-Null
        }
    }
}

# add a new CRAWL component
function New-CrawlComponent ($topology, $instance) {
    if ($debug) {
	    New-SPEnterpriseSearchCrawlComponent -SearchTopology $topology -SearchServiceInstance $instance
    }
    else {
        New-SPEnterpriseSearchCrawlComponent -SearchTopology $topology -SearchServiceInstance $instance | Out-Null
    }
}

# add a new CONTENT PROCESSING component
function New-ContentProcessingComponent ($topology, $instance) {
    if ($debug) {
        New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $topology -SearchServiceInstance $instance
    }
    else {
        New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $topology -SearchServiceInstance $instance | Out-Null
    }
}

# add a new ANALYTICS PROCESSING component
function New-AnalyticsProcessingComponent ($topology, $instance) {
    if ($debug) {
        New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $topology -SearchServiceInstance $instance
    }
    else {
        New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $topology -SearchServiceInstance $instance | Out-Null
    }
}

#endregion SEARCH COMPONENT HELPERS

#region COLLAPSED SEARCH ROLES

# ALL COMPONENTS
function New-AllComponentsServer ($topology, $instance, $indexPartition, $indexLocation) {
	New-QueryProcessingComponent $topology $instance
	New-AdminComponent $topology $instance
	New-IndexComponent $topology $instance $indexPartition $indexLocation
    New-CrawlComponent $topology $instance
    New-ContentProcessingComponent $topology $instance
    New-AnalyticsProcessingComponent $topology $instance
}

# ADMIN, QUERY & INDEX
function New-AdminQueryIndexServer ($topology, $instance, $indexPartition, $indexLocation) {
	New-QueryProcessingComponent $topology $instance
	New-AdminComponent $topology $instance
	New-IndexComponent $topology $instance $indexPartition $indexLocation
}

# CRAWL, CONTENT PROC & ANALYICS PROC
function New-CrawlContentAnalyticsServer ($topology, $instance) {
	New-CrawlComponent $topology $instance
    New-ContentProcessingComponent $topology $instance
    New-AnalyticsProcessingComponent $topology $instance
}
#endregion COLLAPSED SEARCH ROLES

function Test-SearchServices () {

    $searchOK = $true
    if ($searchServers.Count -eq 1) {
        if (Get-Service -Name SPSearchHostController -ComputerName $searchServers[0] | Where-Object { $_.Status -ne "Running" }) {
            Write-Warning -Message "Search Host Controller not started on $server"
            $searchOK = $false
        }
        if (Get-SPEnterpriseSearchServiceInstance -Identity $searchServers[0] | Where-Object { $_.Status -ne "Online" }) {
            Write-Warning -Message "Search not started on $server"
            $searchOK = $false
        }
        if (Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Identity $searchServers[0] | Where-Object { $_.Status -ne "Online" }) {
            Write-Warning -Message "Search Query and Site Settings not started on $server"
            $searchOK = $false
        }
    }
    else {
        foreach ($server in $adminQueryIndexServers) {
            if (Get-Service -Name SPSearchHostController -ComputerName $server | Where-Object { $_.Status -ne "Running" }) {
                Write-Warning -Message "Search Host Controller not started on $server"
                $searchOK = $false
            }        
            if (Get-SPEnterpriseSearchServiceInstance -Identity $server | Where-Object { $_.Status -ne "Online" }) {
                Write-Warning -Message "Search not started on $server"
                $searchOK = $false
            }
            if (Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Identity $server | Where-Object { $_.Status -ne "Online" }) {
                Write-Warning -Message "Search Query and Site Settings not started on $server"
                $searchOK = $false
            }
        }
        foreach ($server in $crawlContentAnalyticsServers) {
             if (Get-Service -Name SPSearchHostController -ComputerName $server | Where-Object { $_.Status -ne "Running" }) {
                Write-Warning -Message "Search Host Controller not started on $server"
                $searchOK = $false
            }
            if (Get-SPEnterpriseSearchServiceInstance -Identity $server | Where-Object { $_.Status -ne "Online" }) {
                Write-Warning -Message "Search not started on $server"
                $searchOK = $false
            }
        }
    }
    return $searchOK
}        

#endregion FUNCTIONS

#region MAIN
Write-Output "$(Get-Date -Format T) : Search Topology Start on $env:ComputerName"

#region INIT_CHECKS
try {
    # Check the box we are running on is a Search box, or SingleServerFarm
    # 2013 version (no minrole)
    if (!(Test-SearchServices)) {
        Write-Warning -Message "One or more servers do not have the required services started."
        Write-Warning -Message "Script execution halted!"
        Exit
    }

    if ($changeIndexLocation) {
        # Create the folder on disk for the search index.
        # It must exist on the machine running this script AND every machine hosting the Index Component
        Write-Output "$(Get-Date -Format T) : Creating Search Index location..."

        foreach ($server in $adminQueryIndexServers) {
            New-Item -Path \\$server\$IndexLocationDrive$\$IndexLocationPath -ItemType directory -force | Out-Null
    
            # check folder is empty
            $index = (Get-ChildItem \\$server\$IndexLocationDrive$\$IndexLocationPath -Force | Measure-Object).Count
            if ( $index -ne 0) {
                Write-Warning -Message "Please ensure the Index Location folder is empty on $server."
                Write-Host "Script execution halted!" -ForegroundColor Red
                Exit
            }
        }
    }
    # we are good... 
    Write-Output "$(Get-Date -Format T) : Initial checks complete, proceeding..."
    if ($debug) { Pause }
}
catch {
    Write-Host "OOOPS! We failed during initial search checks." -ForegroundColor Red
    $_
    Exit
}
#endregion INIT_CHECKS

#region SSA_TOPOLOGY 
try {
    $indexLocation = ""
    if ($changeIndexLocation) { $indexLocation = $IndexLocationDrive + ":\" + $IndexLocationPath }    

    $searchServiceApp = Get-SPEnterpriseSearchServiceApplication $SearchServiceApplicationName

    Write-Output "$(Get-Date -Format T) : Creating new search topology..."
    # grab the current (initial) topology and create our new one
    $initialTopology = $searchServiceApp | Get-SPEnterpriseSearchTopology -Active 
    $newTopology = $searchServiceApp | New-SPEnterpriseSearchTopology

    # add the components to the new topology
    if ($SearchServers.Count -gt 0 -and $SearchServers.Count -le 2) {
        # Single Server or Two Servers
        foreach ($server in $searchServers) {
            Write-Output "$(Get-Date -Format T) : Creating search components on $server..."
            $instance = Get-SPEnterpriseSearchServiceInstance -Identity $server
            New-AllComponentsServer $newTopology $instance 0 $indexLocation
        }
    }

    else {
        # assign the "roles" to the servers
        foreach ($server in $adminQueryIndexServers) {
            Write-Output "$(Get-Date -Format T) : Creating search components on $server..."
            $instance = Get-SPEnterpriseSearchServiceInstance -Identity $server
            New-AdminQueryIndexServer $newTopology $instance 0 $indexLocation
        }
    
        foreach ($server in $crawlContentAnalyticsServers) {
            Write-Output "$(Get-Date -Format T) : Creating search components on $server..."
            $instance = Get-SPEnterpriseSearchServiceInstance -Identity $server
            New-CrawlContentAnalyticsServer $newTopology $instance
        }
    }
    if ($debug) {
        Write-Output "$(Get-Date -Format T) : Components Assigned, OK to Proceed?"
        Pause
    }

    # set the active topology to be the one we just created
    Write-Output "$(Get-Date -Format T) : Setting active search topology..."
    Write-Output "$(Get-Date -Format T) : This usually takes around 10 minutes for a five server topology..."
    Set-SPEnterpriseSearchTopology -Identity $newTopology

    # cleaning up previous (initial) topology
    Write-Output "$(Get-Date -Format T) : Removing old topology..."
    Remove-SPEnterpriseSearchTopology -Identity $initialTopology -Confirm:$false
    Write-Output "$(Get-Date -Format T) : Search Topology Done!"
}
catch {
    Write-Host "OOOPS! We failed during Search Topology Configuration." -ForegroundColor Red
    $_
}
#endregion SSA_TOPOLOGY

#endregion MAIN
#EOF