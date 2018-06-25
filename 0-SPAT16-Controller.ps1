#region Header
<#  
.SYNOPSIS  
	SharePoint Automation Toolkit

.DESCRIPTION  
	
.NOTES  
	File Name  : 0-SPAT16-Controller.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : Faith and Patience 

    Version    : 4.0

    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

        UPDATE THE VARIABLES IN THE VARS_TO_UPDATE REGION
            Futher comments in there

        REQUIRES: PSRemoting and CredSSP enabled on all servers
                  SP binaries allready installed on all servers
                  All accounts created in Active Directory

        

        WILL CALL EXTERNAL SCRIPTs
            - MUST BE IN SAME FOLDER (and resolvable)


    04/04/2016 - mods for 2016


    TODO: Change Web App to not return
    TODO: FARM FUNCTIONS Write Host
    TODO: CHeck IP in IIS Bindings Script


    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
	
.LINK  
	
.PARAMETER File  
	The configuration file
#>
#endregion

#region VARS_TO_UPDATE

#####################################################################
# these you update to reflect your environment
#
#####################################################################
# GLOBAL

$customer = "10 SERVER FARM"             # only output in debug
$debug = $false                          # output additional debug
$debugSearch = $false                    # output additional debug for SSA
$checkAdmins = $false                    # validate local admin requirements?
$ChangeLogLocations = $true              # modify log file location?
$sslWebApps = $true                      # Create SSL Web Sites?
$Upgrade = $false                        # Perform B2B Upgrade

#####################################################################
# SQL SERVER DETAILS - Aliases to create and then use

# configAliasName will be the Default Database Server
# will be used for ConfigDB, Central Admin ContentDB,
# and all Service App DBs except Usage and Search
# if you only wish to use one alias, just make them all the same
$configAliasName = "SPCONFIG"              # SQL Alias (CONFIG, CA and SAs)
$configServerName = "FABSQL1"              # SQL Server Name
$configInstanceName = ""                   # SQL Instance Name (Empty if default)
$configPort = "1433"                       # SQL Port

# content1AliasName will be used for initial Content Databases
$content1AliasName = "SPCONTENT"          # SQL Alias (CONTENT)
$content1ServerName = "FABSQL1"            # SQL Server Name
$content1InstanceName = ""                 # SQL Instance Name (Empty if default)
$content1Port = "1433"                     # SQL Port

# searchAliasName will be used for all Search Databases
$searchAliasName = "SPSEARCH"              # SQL Alias (SEARCH)
$searchServerName = "FABSQL1"              # SQL Server Name
$searchInstanceName = ""                   # SQL Instance Name (Empty if default)
$searchPort = "1433"                       # SQL Port

# logAliasName will be used for Usage Database
$logAliasName = "SPLOG"                    # SQL Alias (USAGE)
$logServerName = "FABSQL1"                 # SQL Server Name
$logInstanceName = ""                      # SQL Instance Name (Empty if default)
$logPort = "1433"                          # SQL Port


#####################################################################
# ACCOUNTS
# do NOT include the domain, this is added automatically

$accounts = @{
    "Setup" = "administrator"
    "Farm" = "sppfarm"
    "Services" = "sppservices"
    "Web Applications" = "sppcontent"
    "Content Access" = "sppcontentaccess"
}

# Object cache accounts
$objectCacheAdmin = "sppcacheadmin"
$objectCacheReader = "sppcachereader"

# default site collection owner
$siteCollectionOwner = "administrator"


#####################################################################
# FARM DETAILS

$farmPrefix = "SP16_Farm"             # Used as Prefix for DB Names
$outgoingMailServer = "SMTP"  # SMTP Server (DO NOT INCLUDE DOMAIN)
$outgoingMailFromAddress = "noreply"  # Do NOT include domain

#####################################################################
# LOG LOCATIONS
$iisLogLocation = "c:\Logs\IIS"
$ulsLocation = "c:\logs\uls"
$healthLocation = "c:\logs\usage"

#####################################################################
# DISTRIBUTED CACHE CONFIGURATION
$dcMaxConnections = 2
$dcTimeout = "3000"

#####################################################################
# TOPOLOGY OPTIONS

# The servers in the farm and any WAC servers (and thier role).
# options are:
#         DistributedCache, WebFrontEnd, Application, 
#         Search, Wac, DistributedCacheWebFrontEnd
#
$serverRoleOptional = $false       # false will build MinRole farm

$farmServers = @{
    "fabsp01" = "DistributedCache"
    "fabsp02" = "DistributedCache"
    "fabsp03" = "WebFrontEnd"
    "fabsp04" = "WebFrontEnd"
    "fabsp05" = "Application"
    "fabsp06" = "Application"
    "fabsp07" = "Search"
    "fabsp08" = "Search"
    "fabsp09" = "Search"
    "fabsp10" = "Search"
}

# the servers which will run Index, Query and Admin
$adminQueryIndexServers = ("fabsp07", "fabsp08")

# the servers which will run Crawl, Content and Analytics Processing
$crawlContentAnalyticsServers = ("fabsp09", "fabsp10")


#####################################################################
# CENTRAL ADMINISTRATION
$caHostName = "spca"                     # do not include domain name
$caCertName = "spca.fabrikam.com"        # Cert friendly name

# hash table of Web Servers and IP Addresses.
# if using NLB, use the same IP (Cluster IP Address) for each server
$caIpAddresses = @{
    "FABSP03" = "10.2.1.30"
    "FABSP04" = "10.2.1.30"
 }


#####################################################################
# WEB APPLICATIONS (do NOT include domain name host names)

# intranet web application details
$portalAppName = "SharePoint Intranet"              # display name
$portalHostName = "intranet"                        # host name
$portalCertName = "intranet.fabrikam.com"           # Cert friendly name
$portalDBName = $farmPrefix + "_Content_Intranet"   # ContentDB name
# Hash table of Web Servers and IP Addresses
$portalIpAddresses = @{
    "FABSP03" = "10.2.1.31"
    "FABSP04" = "10.2.1.31"
}

# mysite host web application details
$oneDriveAppName = "SharePoint OneDrive"              # display name
$oneDriveHostName = "onedrive"                             # host name
$oneDriveCertName = "onedrive.fabrikam.com"                # Cert friendly name
$oneDriveDBName = $farmPrefix + "_Content_OneDrive"   # ContentDB name
# Hash table of Web Servers and IP Addresses
$oneDriveIpAddresses = @{
    "FABSP03" = "10.2.1.32"
    "FABSP04" = "10.2.1.32"
}



#####################################################################
# SEARCH
$changeContentAccessAccount = $true
$configureSearchCentre = $true
$configureContinuousCrawl = $true
$addSPS3S = $true
$changeIndexLocation = $true
$indexLocationDrive = "C"
$indexLocationPath = "SearchData"

#####################################################################
# APPS
$appsUrl = "apps.intranet"  # do not include domain name
$appsPrefix = "app"

#####################################################################
# WAC
$wacHostName = "wac"
$wacCertName = "wac.fabrikam.com"                # Cert friendly name
$wacLogLocation = "c:\Logs\WAC"
$wacCacheLocation ="c:\WACCache"
$wacRenderCacheLocation = "c:\WACRenderCache"

#####################################################################

#endregion VARS_TO_UPDATE

#region VARS_OPTIONAL

# you only need to change these if you don't want the 'standard'
# configuration. Leave them alone if you don't know what you are doing!


#####################################################################
# Farm
$configDatabase = $farmPrefix + "_Config"
$adminContentDB = $farmPrefix + "_Content_Admin"

#####################################################################
# outgoing email
$outgoingMailReplyToAddress = $outgoingMailFromAddress
$outgoingMailCharSet = 65001

#####################################################################
# APP POOLS AND SERVICE APPLICATIONS

# Content Web Applications Application Pool
$waAppPoolName = "SharePoint Content"

# Service Applications Application Pool
$saAppPoolName = "SharePoint Web Services Default"
$saSuffix = "Service Application"    



 # Service App Names and Settings
$stateName = "State $saSuffix"
$stateDBName = $farmPrefix + "_State"
$usageName = "Usage and Health Data Collection $saSuffix"
$usageDBName = $farmPrefix + "_Usage"
$subsName = "Subscription Settings $saSuffix"
$subsDBName = $farmPrefix + "_SubscriptionSettings"
$appsName = "App Management $saSuffix"
$appsDBName = $farmPrefix + "_AppManagement"
$mmsName = "Managed Metadata $saSuffix"
$mmsDBName = $farmPrefix + "_ManagedMetadata"
$bcsName = "Business Data Connectivity $saSuffix"
$bcsDBName = $farmPrefix + "_BusinessDataConnectivity"
$wasName = "Word Automation $saSuffix"
$wasDBName = $farmPrefix + "_WordAutomation"
$mtsName = "Machine Translation $saSuffix"
$mtsDBName = $farmPrefix + "_MachineTranslation"
$pasName = "PowerPoint Automation $saSuffix"
$visioName = "Visio Graphics $saSuffix"
$accessName = "Access $saSuffix"

# Secure Store
$sssName = "Secure Store $saSuffix"
$sssDBName = $farmPrefix + "_SecureStore"
$sssAuditing = $false
$sssSharing = $false
$sssAuditLogMaxSize = ""

# User Profile
$upaName = "User Profile $saSuffix"
$upaProfileDBName = $farmPrefix + "_UserProfile_Profile"
$upaSocialDBName = $farmPrefix + "_UserProfile_Social"
$upaSyncDBName = $farmPrefix + "_UserProfile_Sync"
$mySiteManagedPath = "personal"

# Search
$searchName = "Search $saSuffix"
$searchDbName = $farmPrefix + "_Search"

#####################################################################
#endregion VARS_OPTIONAL

#region VARS_NEVERUPDATE 

# these are 'statics' for the script only

$caName = "SharePoint Central Administration v4" # never update this
$centralAdminPort = 443                          # Port for CA
$distributedCacheServiceAccountFixed = $false    # do not change

#####################################################################
# External Scripts
$searchTopologyScript = ".\Configure-SearchTopology.ps1"
$joinFarmScript = ".\Join-Farm.ps1"
$upgradeScript = ".\Update-Psc.ps1"
$distributedCacheIdentityScript = ".\Set-DistributedCacheIdentity.ps1"
$distCacheAddScript = ".\Add-DistCache.ps1"
$distCacheGcScript = ".\Update-DistCacheGc.ps1"
$iisBindingsScript = ".\Configure-IisBindings.ps1"
$upaCreationScript = ".\New-UserProfileService.ps1"
$upsStartScript = ".\Start-UserProfileSync.ps1"
$testAdminScript = ".\Test-IsAdmin.ps1"
$createWacFarmScript = ".\New-WacFarm.ps1"
$iisConfigScript = ".\Configure-Iis.ps1"
$loopbackScript = ".\Configure-Loopback.ps1"
$sqlAliasScript = ".\New-SqlAlias.ps1"
$shellAdminScript  = ".\Add-ShellAdmin.ps1"
$crlBypassScript  = ".\Configure-CrlBypass.ps1"
$SearchServiceApplicationScript = ".\New-SearchServiceApplication.ps1"
$StartAddressScript = ".\New-StartAddress.ps1"

#endregion VARS_NEVERUPDATE

# =============================================================================
# =============================================================================

#region INIT
$global:time = Set-PSBreakpoint -Variable time -Mode Read -Action {$global:time = Get-Date -Format T}
Clear-Host
Write-Host "******************************************************************" -ForegroundColor Cyan
Write-Host "* Starting SharePoint Farm Build for $customer" -ForegroundColor Cyan
Write-Host "******************************************************************" -ForegroundColor Cyan
Write-Output "$time : Running Initialisation..."
if ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -EA 0) -eq $null) { Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" }
. ".\Farm-Functions.ps1"
$domain = $env:USERDOMAIN    
$domainFqdn = $env:USERDNSDOMAIN
$objectCacheAdmin = "$domain\$objectCacheAdmin"
$objectCacheReader = "$domain\$objectCacheReader"
$farmAccount = "$domain\" + $accounts.Farm
$ownerAlias = "$domain\$siteCollectionOwner"
$ownerEmail = "$siteCollectionOwner@$domainFqdn"
$caHostName = "$caHostName.$domainFqdn"
$portalHostName = "$portalHostName.$domainFqdn"
$oneDriveHostName = "$oneDriveHostName.$domainFqdn"
$wacHostName = "$wacHostName.$domainFqdn"
$appsUrl = "$appsUrl.$domainFqdn"
$outgoingMailServer = "$outgoingMailServer.$domainFqdn"
if ($debug) {
    Write-Host "Domain: $domain" -ForegroundColor Magenta   
    Write-Host "Domain FQDN: $domainFqdn" -ForegroundColor Magenta
    Write-Host "Object Cache Admin: $objectCacheAdmin" -ForegroundColor Magenta
    Write-Host "Object Cache Reader: $objectCacheReader" -ForegroundColor Magenta
    Write-Host "Farm Account: $farmAccount" -ForegroundColor Magenta
    Write-Host "Site Collection Owner: $ownerAlias" -ForegroundColor Magenta
    Write-Host "Site Collection Owner Email: $ownerEmail" -ForegroundColor Magenta
    Write-Host "Central Admin Host Name: $caHostName" -ForegroundColor Magenta
    Write-Host "Portal Host Name: $portalHostName" -ForegroundColor Magenta
    Write-Host "OneDrive Host Name: $oneDriveHostName" -ForegroundColor Magenta
    Write-Host "Office Web Apps Host Name: $wacHostName" -ForegroundColor Magenta
    Write-Host $PSScriptRoot
    Pause
}



if ($sslWebApps) {
    $caUrl = "https://$caHostName"
    $portalUrl = "https://$portalHostName"
    $oneDriveUrl = "https://$oneDriveHostName"
    $wacUrl = "https://$wacHostName"
}
else {
    $caUrl = "http://$caHostName"
    $portalUrl = "http://$portalHostName"
    $oneDriveUrl = "http://$oneDriveHostName"
    # WAC is not supported without SSL in this script
}
#endregion INIT

#region CREDS

Write-Output "$time : Credential Requests..."

$creds = @{}

# loop thru hash table and get credentials
ForEach ($account in $accounts.Keys)
{
    $userName = "$domain\$($accounts.Item($account))"
    $cred = Get-Credential -UserName $userName -Message "Please provide the credentials for the $account Account: "
    # validate the creds
    if (!(Test-Credentials $cred)) {
        Throw "The credentials provided for the $account Account are invalid!"
    }
    else {
        $creds.Add($account, $cred)
    }
}

$passPhrase = Read-Host -AsSecureString -Prompt "Please provide the SharePoint Farm Passphrase: "

if ($checkAdmins) {
    if (!(Test-IsAdmin $farmAccount)) {
        Write-Warning -Message "The farm account ($farmAccount) is not a local machine administrator on the controller ($env:ComputerName)! You can either stop script execution or continue."
        Pause 
    }
}

    #endregion CREDS

# =============================================================================
# RUN TO HERE TO INITIALISE SESSION
# ============================================================================


#region MACHINE_PREP
try {
    Write-Output "$time : Performing Server Preparation..."

    foreach ($server in $farmServers.Keys) {
        $role = $farmServers.Item($server)

        # IIS (kill default web app and app pool, set log location)
        If ($ChangeLogLocations) {
            Invoke-Command -ComputerName $server -FilePath $iisConfigScript `
                           -ArgumentList $iisLogLocation `
                           -Credential $creds.Setup -Authentication Credssp
        } Else {
            Invoke-Command -ComputerName $server -FilePath $iisConfigScript `
                           -Credential $creds.Setup -Authentication Credssp
        }

        # Disable Loopback Check on all servers
        Invoke-Command -ComputerName $server -FilePath $loopbackScript `
                       -Credential $creds.Setup -Authentication Credssp

        # Bypass CRL Checking for the .Net Framework on all servers
        #Write-Verbose -Message "$time : Configuring .NET Framework CRL Bypass..."
        #Invoke-Command -ComputerName $server -FilePath $crlBypassScript `
        #               -Credential $creds.Setup -Authentication Credssp

        # Create SQL Aliases
        If ($role -ne "Wac") {
            Invoke-Command -ComputerName $server -FilePath $sqlAliasScript `
                           -ArgumentList $content1AliasName, $content1ServerName, $content1InstanceName, $content1Port `
                           -Credential $creds.Setup -Authentication Credssp

            Invoke-Command -ComputerName $server -FilePath $sqlAliasScript `
                           -ArgumentList $configAliasName, $configServerName, $configInstanceName, $configPort `
                           -Credential $creds.Setup -Authentication Credssp

            Invoke-Command -ComputerName $server -FilePath $sqlAliasScript `
                           -ArgumentList $searchAliasName, $searchServerName, $searchInstanceName, $searchPort `
                           -Credential $creds.Setup -Authentication Credssp

            Invoke-Command -ComputerName $server -FilePath $sqlAliasScript `
                           -ArgumentList $logAliasName, $logServerName, $logInstanceName, $logPort `
                           -Credential $creds.Setup -Authentication Credssp
        }
        
        # Enable BackgroundGC - we do this on all machines in case the topology changes in future
        if ($role -ne "Wac") {
            Invoke-Command -ComputerName $server -FilePath $distCacheGcScript `
                           -Credential $creds.Setup -Authentication Credssp
        }
    
    }

    Write-Output "$time : Server Preparation complete!"
}
catch {
    Write-Host "OOOPS! We failed during server preperation." -ForegroundColor Red
    $_
    Pause
}

#endregion MACHINE_PREP

#region FARM_CREATION

try {
    Write-Output "$time : Starting Farm Creation..."
    Write-Output "$time : Creating Configuration Database and Central Admin Content Database..."
    
    $FirstServerRole = $FarmServers.$env:ComputerName

    # note farm creation can stall due to RPC server is unavailable but it thinks it's worked 
    # and Get-SPFarm reports a status of Online! this exception falls thru, managing takes
    # lots of aditional work (not included to keep this simple).
    If ($serverRoleOptional) {
        # we will build every box as Custom. not the only option/way. Works like 2013.
        New-SPConfigurationDatabase -DatabaseServer $configAliasName -DatabaseName $configDatabase `
                                    -AdministrationContentDatabaseName $adminContentDB `
                                    -Passphrase $passphrase -FarmCredentials $creds.Farm `
                                    -ServerRoleOptional -SkipRegisterAsDistributedCacheHost
    } 
    Else {
        # if we aren't on WebFront or Application, provide a warning and chance to bail
        If ($FirstServerRole -ne "WebFrontEnd" -and $FirstServerRole -ne "Application") {
            Write-Warning "This server is not of role WebFrontEnd or Application."
            Pause
        }

        # use the MinRole role
        New-SPConfigurationDatabase -DatabaseServer $configAliasName -DatabaseName $configDatabase `
                                    -AdministrationContentDatabaseName $adminContentDB `
                                    -Passphrase $passphrase -FarmCredentials $creds.Farm `
                                    -LocalServerRole $FirstServerRole -SkipRegisterAsDistributedCacheHost

    }

    # won't actually respect SilentlyContinue...
    $SpFarm = Get-SPFarm -ErrorAction SilentlyContinue -ErrorVariable $err

    if ($SpFarm -eq $null -or $err) {
       Write-Host "Unable to verify farm creation." -ForegroundColor Yellow
       Write-Host "Script execution halted!" -ForegroundColor Red
       Pause
    }
    else {
        #Sometimes (e.g. RPC unavailable) we will fall thru to here as the configdb has been 
        #created but it fails so these will all fail
        Write-Output "$time : ACLing SharePoint Resources..."
        Initialize-SPResourceSecurity
        Write-Output "$time : Installing Services..."
        Install-SPService | Out-Null
        Write-Output "$time : Installing Features..."
        Install-SPFeature -AllExistingFeatures | Out-Null

        # we install CA on first server in the farm, it's not neccessary to do so
        # this model means we 'should' run on a Web server first
        Write-Output "$time : Creating Central Administration..."              
        New-SPCentralAdministration -Port $centralAdminPort -WindowsAuthProvider Kerberos
        
        Write-Output "$time : Installing Help..."
        Install-SPHelpCollection -All        
        Write-Output "$time : Installing Application Content..."
        Install-SPApplicationContent

        Write-Output "$time : Restarting SharePoint Timer Service..."
        Restart-Service -Name "SPTimerV4"

        Write-Output "$time : Configuring CEIP Settings..."
        $spfarm.CEIPEnabled = $false
        $spfarm.Update()
        $spfarm = Get-SPFarm

        Write-Output "$time : Configuring Outgoing Email..."
        $outgoingMailFromAddress = "$outgoingMailFromAddress@$domainFqdn" 
        $outgoingMailReplyToAddress = $outgoingMailFromAddress
        $centralAdmin = Get-SPWebApplication -IncludeCentralAdministration | 
                        Where-Object {$_.IsAdministrationWebApplication}
        $centralAdmin.UpdateMailSettings($outgoingMailServer, $outgoingMailFromAddress, `
                                         $outgoingMailReplyToAddress, $outgoingMailCharSet)

        # No longer neccessary in 2016 as we set the port correctly when using 443
        #Write-Output "$time : Updating Central Administration URL..."
        #if ($centralAdminPort -eq 443) {
        #    Set-SPCentralAdministration -Port 443 -Confirm:$false
            #we configure the Alternate URL after topology (to support multiple CAs)
        #}

        if ($ChangeLogLocations) {
            Write-Output "$time : Setting Log locations..."
            Set-SPDiagnosticConfig -LogLocation $ulsLocation
            Set-SPUsageService -UsageLogLocation $healthLocation
        }

        Write-Output "$time : Removing and reloading Snapin..."
        Remove-PSSnapin -Name "Microsoft.SharePoint.PowerShell"
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"

        Write-Output "$time : Farm Creation Done!"
    }
}
catch [System.Exception]{
    Write-Host "OOOPS! We failed during Farm Creation." -ForegroundColor Red
    $_
    Pause
}

#endregion FARM_CREATION

#region MANAGED_ACCOUNTS
   
# Create Managed Accounts
try {
    Write-Output "$time : Creating Managed Accounts..."
    $serviceManagedAccount = New-SPManagedAccount -Credential $creds.Services
    $appPoolManagedAccount = New-SPManagedAccount -Credential $creds.'Web Applications'
    Write-Output "$time : Managed Accounts Created!"
}
catch {
    Write-Host "OOOPS! We failed during Managed Account creation." -ForegroundColor Red
    $_
    Pause
}

#endregion MANAGED_ACCOUNTS

#region SERVICE_IDENTITY

try {
    Write-Output "$time : Configuring Search Service Account..."
    Get-SPEnterpriseSearchService | Set-SPEnterpriseSearchService -ServiceAccount $creds.Services.UserName -ServicePassword $creds.Services.Password

    Write-Output "$time : Configuring Distributed Cache Service Account..."
    $dcService = $spfarm.Services | Where-Object {$_.TypeName -eq "Distributed Cache"}
    $dcService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
    $dcService.ProcessIdentity.ManagedAccount = $serviceManagedAccount
    $dcService.ProcessIdentity.Update() 
    # deploy won't work as there is no cache cluster yet - expected error of CacheHostInfo is null
    Write-Output "$time : Service Identities Complete!"
}
catch {
    Write-Host "OOOPS! We failed during Service Identity fixup." -ForegroundColor Red
    $_
    Exit
}
#endregion SERVICE_IDENTITY

#region MINROLE_CONFIG

try {
    Write-Output "$time : Configuring AutoProvision..."

    # BUG - stop-spservice can error but not throw an exception
    Stop-SPService -Identity "Claims to Windows Token Service" -Confirm:$false | Out-Null
    #TODO subsettings is not autoprovisioned by default until the SA is created
    Write-Output "$time : AutoProvision configuration Complete!"
}
catch {
    Write-Host "OOOPS! We failed during AutoProvision configuration." -ForegroundColor Red
    $_
    Pause
}
#endregion MINROLE_CONFIG

#region FARM_JOIN

try {
    Write-Output "$time : Joining servers to the farm..."
    ForEach ($server in $farmServers.Keys) {
        $role = $farmServers.Item($server)
        if ($role -ne "Wac" -and $server -ne $env:ComputerName) {
            Invoke-Command -ComputerName $server -FilePath $joinFarmScript `
                           -ArgumentList $server, $configAliasName, $configDatabase, `
                                         $passphrase, $role, $serverRoleOptional `
                            -Credential $creds.Setup -Authentication Credssp
        }
    }
    Write-Output "$time : All servers joined to farm!"
}
catch {
    Write-Host "OOOPS! We failed calling $joinFarmScript." -ForegroundColor Red
    $_
    Pause
}
#endregion FARM_JOIN

#region DC_SETTINGS
try {
    Set-DistributedCacheConfiguration $dcMaxConnections $dcTimeout
}
catch {
    Write-Host "OOOPS! We failed configuring Distributed Cache." -ForegroundColor Red
    $_
    Pause
}
#endregion DC_SETTINGS

#region DEPLOY_CA
try {

    $FirstServerRole = $FarmServers.$env:ComputerName
    ForEach ($server in $farmServers.Keys) {
        $role = $farmServers.Item($server)
        If ($role -eq $FirstServerRole -and $server -ne $env:ComputerName) {
            # deploy on every server which is of same role as the 1st server in the farm
            Write-Output "$time : Deploying Central Administration to server $server..."
            Invoke-Command -ComputerName $server -Credential $creds.Setup -Authentication Credssp `
                           -ScriptBlock {
                Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"
                New-SPCentralAdministration
            }
            #Get-SPServiceInstance -Server $server | Where-Object { $_.TypeName -eq "Central Administration" } | Start-SPServiceInstance | Out-Null
            # ensure CA is up to avoid issues with bindings later
            #While (Get-SPServiceInstance -Server $server | Where-Object { $_.TypeName -eq "Central Administration" -and $_.Status -eq "Online" }) {
            #    Start-Sleep -Seconds 15
            #}
            Write-Output "$time : Central Administration deployed to additional servers!"
        }
    }
}
catch {
    Write-Host "OOOPS! We failed deploying Central Administration." -ForegroundColor Red
    $_
    Pause
}
#endregion DEPLOY_CA

#region CA_BINDINGS
try {
    Write-Output "$time : Configuring Central Admin..."

    if ($sslWebApps) {
        foreach ($server in $caIpAddresses.Keys) {
            Invoke-Command -ComputerName $server -FilePath $iisBindingsScript `
                           -ArgumentList $caName, $caHostName, $caIpAddresses.Item($server), $caCertName `
                           -Credential $creds.Setup -Authentication Credssp
        }
    }

    Write-Output "$time : Configuring Internal URL for Central Administration..."
    # remove the 2nd, 3rd, 4th (etc) Alternate URL (do this to avoid exceptions when updating with name already in collection
    Get-SPAlternateURL | Where-Object {$_.PublicUrl -ne $_.IncomingUrl} | Remove-SPAlternateURL -Confirm:$false
    # get the remaining AAM and fix it
    $alternateURL = Get-SPAlternateURL
    Set-SPAlternateURL -Identity $alternateURL -url $caUrl
    
    Write-Output "$time : Central Admin Bindings complete!"
}
catch {
    Write-Host "OOOPS! We failed configuring Central Admin on $server." -ForegroundColor Red
    $_
    Pause
}
#endregion CA_BINDINGS

#region WEB_APPLICATIONS
try {
    Write-Output "$time : Starting Web Applications and Site Collections"

    $appPoolManagedAccount = Get-SPManagedAccount $creds.'Web Applications'.UserName
    New-WebApp-AppPool $waAppPoolName $appPoolManagedAccount

    if ($sslWebApps) {

        # create the web apps using the "host header trick"
        New-SSL-WebApp $waAppPoolName $portalAppName $portalHostName $portalDBName $content1AliasName
        New-SSL-WebApp $waAppPoolName $oneDriveAppName $oneDriveHostName $oneDriveDBName $content1AliasName

        # correct the IIS bindings and add the certificate
        foreach ($server in $portalIpAddresses.Keys) {    
            Invoke-Command -ComputerName $server -FilePath $iisBindingsScript `
                           -ArgumentList $portalAppName, $portalHostName, $portalIpAddresses.Item($server), $portalCertName `
                           -Credential $creds.Setup -Authentication Credssp
        }

        foreach ($server in $oneDriveIpAddresses.Keys) { 
            Invoke-Command -ComputerName $server -FilePath $iisBindingsScript `
                           -ArgumentList $oneDriveAppName, $oneDriveHostName, $oneDriveIpAddresses.Item($server), $oneDriveCertName `
                           -Credential $creds.Setup -Authentication Credssp
        }

        # clean up the SPSecureBinding.HostHeader property
        Remove-SPHostHeader (Get-SPWebApplication -Identity $portalAppName)
        Remove-SPHostHeader (Get-SPWebAPplication -Identity $oneDriveAppName)
    } 
    else {
        # not supported in this version of the script, will not clean up bindings, relies entirely on hostheaders
        $portalWebApp = New-WebApp $waAppPoolName $portalAppName $portalHostName $portalDBName $contentAliasName
        $oneDriveWebApp = New-WebApp $waAppPoolName $oneDriveAppName $oneDriveHostName $oneDriveDBName $content1AliasName
    }
    
    #safety - get the web apps again
    $portalWebApp = Get-SPWebApplication -Identity $portalAppName
    $oneDriveWebApp = Get-SPWebApplication -Identity $oneDriveAppName


    # we could do this by passing in all web apps, but this allows for seperate accounts if needed
    Register-ObjectCacheConfig $portalWebApp $objectCacheAdmin $objectCacheReader
    Register-ObjectCacheConfig $oneDriveWebApp $objectCacheAdmin $objectCacheReader

    #Add-FullControlWebAppPolicy $portalWebApp $adminPolicyUser
    #Add-FullControlWebAppPolicy $oneDriveWebApp $adminPolicyUser

    Write-Output "$time : Creating Managed Paths..."
    Remove-SPManagedPath "sites" -WebApplication $oneDriveWebApp -Confirm:$false
    New-SPManagedPath $mySiteManagedPath -WebApplication $oneDriveWebApp | Out-Null
    New-SPManagedPath "search" -WebApplication $portalWebApp -Explicit | Out-Null
    New-SPManagedPath "apps" -WebApplication $portalWebApp -Explicit | Out-Null
    New-SPManagedPath "installtest" -WebApplication $portalWebApp -Explicit | Out-Null
    Write-Output "$time : Web Applications complete!"
}
catch {
    Write-Host "OOOPS! We failed during Web Application creation." -ForegroundColor Red
    $_
    Pause
}
#endregion WEB_APPLICATIONS

#region SITE_COLLECTIONS

try {
    Write-Output "$time : Creating root Site Collections..."
    $portal = New-SPSite -Url $portalUrl -owneralias $ownerAlias -ownerEmail $ownerEmail -Template "STS#0"

    #ECAL - will fail on expired trial
    Write-Output "$time : Creating Search Center Site Collection..."
    $searchCentre = New-SPSite -Url "$portalUrl/Search" -owneralias $ownerAlias -ownerEmail $ownerEmail -Template "SRCHCEN#0"

    Write-Output "$time : Creating MySite host root Site Collection..."
    $mySiteHost = New-SPSite -Url $oneDriveUrl  -owneralias $ownerAlias -ownerEmail $ownerEmail -Template "SPSMSITEHOST#0"

    Write-Output "$time : Creating AppCatalog Site Collection..."
    $testSite = New-SPSite -Url "$portalUrl/apps" -owneralias $ownerAlias -ownerEmail $ownerEmail -Template "APPCATALOG#0"

    Write-Output "$time : Creating Install Test Site Collection..."
    $testSite = New-SPSite -Url "$portalUrl/installtest" -owneralias $ownerAlias -ownerEmail $ownerEmail -Template "STS#0"

    #Write-Output "$time : Enabling Self Service Site Creation on $oneDriveUrl..."
    Enable-SSSC $onedriveWebApp
    Write-Output "$time : Site Collections complete!"
}
catch {
    Write-Host "OOOPS! We failed during Site Collection creation." -ForegroundColor Red
    $_
    Pause
}
#endregion SITE_COLLECTIONS  

#region CORE_SERVICE_APPLICATIONS

try {
    Write-Output "$time : Service Applications Start"

    Write-Output "$time : Creating Service Application Pool..."
    $serviceManagedAccount = Get-SPManagedAccount $creds.Services.UserName
    $saAppPool = New-SPServiceApplicationPool -Name $saAppPoolName -Account $serviceManagedAccount

    # STATE
    Write-Output "$time : Creating $stateName Application and Proxy..."
    $stateDB = New-SPStateServiceDatabase -Name $stateDBName
    $state = New-SPStateServiceApplication -Name $stateName -Database $stateDB
    $stateProxy = New-SPStateServiceApplicationProxy -Name "$stateName Proxy" -ServiceApplication $state -DefaultProxyGroup

    # USAGE (uses different SQL instance)
    Write-Output "$time : Creating $usageName Application and Proxy..."
    $serviceInstance = Get-SPUsageService
    $usage = New-SPUsageApplication -Name $usageName -DatabaseServer $logAliasName -DatabaseName $usageDBName -UsageService $serviceInstance
    $usageProxy = Get-SPServiceApplicationProxy | Where-Object { $_.TypeName -eq "Usage and Health Data Collection Proxy" }
    $usageProxy.Provision();
    Write-Output "$time : Core Service Applications complete!"
}
catch {
    Write-Host "OOOPS! We failed during creation of core service applications." -ForegroundColor Red
    $_
    Pause
}

#endregion CORE_SERVICE_APPLICATIONS

#region SERVICE_APPLICATIONS

try {
    # yes, we don't use the proxies often here, but we do want them in the workpad
    $saAppPool = Get-SPServiceApplicationPool $saAppPoolName

    # SUBS SETTINGS
    Write-Output "$time : Creating $subsName Application and Proxy..."
    $subs = New-SPSubscriptionSettingsServiceApplication -ApplicationPool $saAppPool -Name $subsName -DatabaseName $subsDBName
    $subsProxy = New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $subs

    # APP MGMT
    Write-Output "$time : Creating $appsName Application and Proxy..."
    $apps = New-SPAppManagementServiceApplication -ApplicationPool $saAppPool -Name $appsName -DatabaseName $appsDBName
    $appProxy = New-SPAppManagementServiceApplicationProxy -ServiceApplication $apps -Name "$appsName Proxy" -UseDefaultProxyGroup

    # MMS
    Write-Output "$time : Creating $mmsName Application and Proxy..."
    $mms = New-SPMetadataServiceApplication -Name $mmsName -ApplicationPool $saAppPool -DatabaseName $mmsDBName
    $mmsProxy = New-SPMetadataServiceApplicationProxy -Name "$mmsName Proxy" -ServiceApplication $mms -DefaultProxyGroup

    # BCS
    Write-Output "$time : Creating $bcsName Application and Proxy..."
    $bcs = New-SPBusinessDataCatalogServiceApplication -Name $bcsName -ApplicationPool $saAppPool -DatabaseName $bcsDBName 
    Get-SPServiceApplicationProxy | Where-Object { $_.Name -eq $bcsName } | remove-spserviceapplicationproxy -Confirm:$false
    $bcsProxy = New-SPBusinessDataCatalogServiceApplicationProxy -Name "$bcsName Proxy" -ServiceApplication $bcs -DefaultProxyGroup

    # SSS
    Write-Output "$time : Creating $sssName Application & Proxy..."
    $sss = New-SPSecureStoreServiceApplication -Name $sssName -ApplicationPool $saAppPool -DatabaseName $sssDBName -auditingEnabled:$sssAuditing -AuditlogMaxSize $sssAuditLogMaxSize -Sharing:$sssSharing
    $sssProxy = New-SPSecureStoreServiceApplicationProxy -Name "$sssName Proxy" -ServiceApplication $sss -DefaultProxyGroup

    # UPA
    Write-Output "$time : Creating $upaName Application & Proxy..."
    $upa = New-SPProfileServiceApplication -Name $upaName -ApplicationPool $saAppPool -ProfileDBName $upaProfileDBName -SocialDBName $upaSocialDBName -ProfileSyncDBName $upaSyncDBName -MySiteHostLocation $oneDriveUrl -MySiteManagedPath $mySiteManagedPath
    $upaProxy = New-SPProfileServiceApplicationProxy -Name "$upaName Proxy" -ServiceApplication $upa -DefaultProxyGroup

    # WAS
    Write-Output "$time : Creating $wasName Application & Proxy..."
    $was = New-SPWordConversionServiceApplication -Name $wasName -ApplicationPool $saAppPool -DatabaseName $wasDBName -Default
    # no proxy cmdlet

    # MTS
    Write-Output "$time : Creating $mtsName Application & proxy..."
    $mts = New-SPTranslationServiceApplication -Name $mtsName -ApplicationPool $saAppPool -DatabaseName $mtsDBName
    Get-SPServiceApplicationProxy | Where-Object {$_.Name -eq $mtsName} | Remove-SPServiceApplicationProxy -Confirm:$false
    $mtsProxy = New-SPTranslationServiceApplicationProxy -Name "$mtsName Proxy" -ServiceApplication $mts -DefaultProxyGroup

    # PAS
    Write-Output "$time : Creating $pasName Application and Proxy..."
    $pas = New-SPPowerPointConversionServiceApplication -ApplicationPool $saAppPool -Name $pasName
    $pasProxy = New-SPPowerPointConversionServiceApplicationProxy -ServiceApplication $pas -Name "$pasName Proxy" -AddToDefaultGroup

    # VISIO
    Write-Output "$time : Creating $visioName Application and Proxy..."
    $visioSA = New-SPVisioServiceApplication -Name $visioName -ApplicationPool $saAppPool
    $visioProxy = New-SPVisioServiceApplicationProxy -Name "$visioName Proxy" -ServiceApplication $visioName

    # ACCESS
    Write-Output "$time : Creating $accessName Application and Proxy..."
    $accessSA = New-SPAccessServicesApplication -Name $accessName -ApplicationPool $saAppPool -Default

    Write-Output "$time : Configuring UPA permissions and administrators..."
    $upa = Get-SPServiceApplication | Where-Object {$_.Name -eq $upaName}
    Grant-ServiceAppPermission $upa $creds.Setup.UserName "Full Control" $false
    Grant-ServiceAppPermission $upa $creds.Services.UserName "Full Control" $false
    Grant-ServiceAppPermission $upa $creds.'Content Access'.UserName "Retrieve People Data for Search Crawlers" $true

    Write-Output "$time : Configuring SSS permissions and administrators..."
    $sss = Get-SPServiceApplication | Where-Object {$_.Name -eq $sssName}
    Grant-ServiceAppPermission $sss $creds.Setup.UserName "Full Control" $true

    Write-Output "$time : Service Applications done!"
}
catch {
    Write-Host "OOOPS! We failed during creation of main service applications." -ForegroundColor Red
    $_
    Exit
}
#endregion SERVICE_APPLICATIONS

#region SEARCH_SA
try {
    $SearchServers = @((Get-SPServer | Where-Object {$_.Role -eq "search" -or $_.Role -eq "SingleServerFarm"}) |
                                       ForEach-Object {$_.Address})
    
    Invoke-Command -ComputerName $SearchServers[0] -FilePath $SearchServiceApplicationScript `
                   -ArgumentList $saAppPoolName, $searchName, $searchAliasName, $searchDbName `
                   -Credential $creds.Setup -Authentication Credssp

    $SearchServiceApp = Get-SPEnterpriseSearchServiceApplication -Identity $searchName

    #Change Content Access Account and clean up old (default) Web App Policy
    if ($changeContentAccessAccount) {
        Write-Output "$time : Configuring the default content access account..."
        Set-SPEnterpriseSearchServiceApplication -Identity $SearchServiceApp `
                        -DefaultContentAccessAccountName $creds.'Content Access'.UserName `
                        -DefaultContentAccessAccountPassword $creds.'Content Access'.Password
                    
        Write-Output "$time : Cleaning up old web app policy..."
        $serviceAccountName = $creds.Services.UserName
        foreach ($webApp in Get-SPWebApplication)
        {
            # the policy doesn't exist after deleting and recreating SSA so on re-run will fail.
            $webApp.Policies.Remove("i:0#.w|$serviceAccountName") 
            $webApp.Update()
        }
    }

    #Configure Search Centre
    if ($configureSearchCentre) {
        Write-Output "$time : Configuring Global Search Centre URL..."
        $searchServiceApp = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceApp
        $searchServiceApp.SearchCenterUrl = "$portalUrl/search"
        $searchServiceApp.Update()
    }

    Write-Output "$time : Configured Search SA properties."
}
catch {
    Write-Host "OOOPS! We failed during creating the Search SA." -ForegroundColor Red
    $_
    Pause
}
#endregion SEARCH_SA

#region SEARCH_TOPOLOGY
try {
    $SearchServers = @((Get-SPServer | Where-Object {$_.Role -eq "search" -or $_.Role -eq "SingleServerFarm"}) |
                                       ForEach-Object {$_.Address})
    Write-Output "$time : This farm has $($SearchServers.Count) Search Servers."

    If ($SearchServers.Count -eq 0) {
        Throw "There are no Search servers in the farm!"
    }
    Else {
        If ($SearchServers.Count -gt 0 -and $SearchServers.Count -le 2) {
            $adminQueryIndexServers = $SearchServers
            $crawlContentAnalyticsServers = $SearchServers
        }

        Invoke-Command -ComputerName $adminQueryIndexServers[0] -FilePath $searchTopologyScript `
                       -ArgumentList $searchName, $changeIndexLocation, $searchServers, `
                       $adminQueryIndexServers, $crawlContentAnalyticsServers, $indexLocationDrive, `
                       $indexLocationPath, $debugSearch `
                       -Credential $creds.Setup -Authentication Credssp
    }
}
catch {
    Write-Host "OOOPS! We failed during calling Invoke Command to modify Search Topology." -ForegroundColor Red
    $_
    Pause
}
#endregion SEARCH_TOPOLOGY

#todo: unauthorised operation
#region SEARCH_CONTENT_SOURCE
try {
    $SearchServers = @((Get-SPServer | Where-Object {$_.Role -eq "search" -or $_.Role -eq "SingleServerFarm"}) |
                                       ForEach-Object {$_.Address})

    if ($sslWebApps) { 
        $profileStartAddress = "sps3s://$oneDriveHostName"
    } else {
        $profileStartAddress = "sps3://$oneDriveHostName"
    }

    # turn on continuous crawl 
    # and content source fix up for SSL profiles...
    # we know we only have the default content source (Local SharePoint Sites)

    # IF WE TRY AND ADD A START ADDRESS WHEN NOT ON A SEARCH BOX
    # we will get "attempted to perform an unauthorised operation" error, but it works! (yes, really)
    # so we do that part on a search box (sigh) but actually it's totally random!

    # TODO - more testing on the start address

    # TODO - check out profile start address behaviour when not doing SSL

    if ($addSPS3S -or $configureContinuousCrawl) {
        Write-Output "$time : Configuring Content Source..."
        if ($addSPS3S) {
            # Call script on a search box
            # fails if done on the same box the SA was created on! (8) works on 9
            # hence the sillyness on -ComputerName
            Invoke-Command -ComputerName $SearchServers[$searchServers.Count - 1] -FilePath $StartAddressScript `
                           -ArgumentList $searchName, $profileStartAddress `
                           -Credential $creds.Setup -Authentication Credssp
        }
        if ($configureContinuousCrawl) {
            $searchServiceApp = Get-SPEnterpriseSearchServiceApplication -Identity $searchName
            $contentSource = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $searchServiceApp
            Set-SPEnterpriseSearchCrawlContentSource -Identity $contentSource -EnableContinuousCrawls $true
            #todo: setup schedules, default for now
        }
        Write-Output "$time : Content Source Configuration Complete!"
    }
}
catch {
    Write-Host "OOOPS! We failed during content source configuration." -ForegroundColor Red
    $_
    Pause
}
#endregion SEARCH_CONTENT_SOURCE

#region SHAREPOINT_APPS
try {
    Write-Output "$time : Configuring SP Apps..."
    Set-SPAppDomain $appsUrl
    Set-SPAppSiteSubscriptionName -Name $appsPrefix -Confirm:$false
    Update-SPAppCatalogConfiguration -Site "$portalurl/apps"
    Write-Output "$time : SP Apps complete!"
}
catch {
    Write-Host "OOOPS! We failed during SP Apps configuration." -ForegroundColor Red
    $_
    Pause
}
#endregion SHAREPOINT_APPS

<#
#todo - test w 2016
#region WAC
try {
    if ($sslWebApps) {

        $wacFarm = $false
    
        ForEach ($server in $farmServers.Keys) {
    
            $role = $farmServers.Item($server)
            if ($role -eq "Wac") {
                if (!$wacFarm) {
                    Invoke-Command -ComputerName $server -FilePath $createWacFarmScript `
                                   -ArgumentList $server, $wacUrl, $wacUrl, $wacCertName, $wacCacheLocation, $wacLogLocation, $wacRenderCacheLocation `
                                   -Credential $creds.Setup -Authentication Credssp
                    $wacFarm = $true
                    Write-Output "$time : WAC Farm Created!"
                }
                else {
                    Write-Output "$time : WAC FARM JOIN NOT IMPLEMENTED!"
                    #Join Farm not implemented
                }
            }
        }

        Write-Output "$time : Connecting SharePoint to Office Web Apps..."
        New-SPWOPIBinding -ServerName $wacHostName | out-null

        Write-Output "$time : Office Web Apps Complete!"
    }
    else {
        Write-Output "$time : Office Web Apps Not Configured without SSL!"
    }
}
catch {
    Write-Host "OOOPS! We failed during calling Invoke Command to create WAC Farm." -ForegroundColor Red
    $_
    Pause
}
#endregion WAC

#not run on FAB
#region CUSTOMER_TWEAKS
try {
    Write-Verbose -Message "$time : Initiating Customer Tweaks..."
   
    Write-Verbose -Message "$time : Configuring Shell Admins..."

    # Add Shell Admin to all databases on the Default Database Server
    # e.g. SPContent 
    # This is all databses except Search and Usage.
    # Run these as farm account to overcome issue with UPA databases having no dbo for the
    # install account
    Invoke-Command -ComputerName $upsServer -FilePath $shellAdminScript `
                   -ArgumentList $upsServer, $adminPolicyUser, $usageDBName, $searchDbName `
                   -Credential $creds.Farm -Authentication Credssp
    Invoke-Command -ComputerName $upsServer -FilePath $shellAdminScript `
                   -ArgumentList $upsServer, $scomUser, $usageDBName, $searchDbName `
                   -Credential $creds.Farm -Authentication Credssp
    
    # Add Shell Admin to all databases on the Secondary Database Server
    # e.g. SPSearch
    # These are the Search Dbs and Usage
    # Overcomes issue with no Farm Account DBO on Secondary database sever
    $usageDB = Get-SPDatabase | Where-Object {$_.Name -eq $usageDBName}
    Add-SPShellAdmin -UserName $adminPolicyUser -database $usageDB
    Add-SPShellAdmin -UserName $scomUser -database $usageDB
    $searchDbs = Get-SPDatabase | Where-Object {$_.Name -like "$searchDbName*"}
    foreach ($database in $searchDbs) {
        Add-SPShellAdmin -UserName $adminPolicyUser -database $database
        Add-SPShellAdmin -UserName $scomUser -database $database
    }

    Write-Verbose -Message "$time : Configuring Farm Administrators..."
    Add-FarmAdmin $adminPolicyUser
    Add-FarmAdmin $scomUser
    Remove-FarmAdmin "BUILTIN\Administrators" 

    Write-Verbose -Message "$time : Exporting SharePoint Root Certificate..."
    $certPath = "$certificatePath\SPRoot.cer"
    if (-not (Test-Path -Path $certificatePath)) {
        New-Item -Path $certificatePath -ItemType directory | Out-Null
    }
    $rootCert = (Get-SPCertificateAuthority).RootCertificate
    $rootCert.Export("Cert") | Set-Content -Path $certPath -Encoding byte


    $script = "Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\AuthRoot | Out-Null"
    foreach ($server in $farmServers.Keys) {
    Write-Verbose -Message "$time : Importing SharePoint Root Certificate on $server..."
    Invoke-Command -ComputerName $server -ScriptBlock ([scriptblock]::Create($script)) `
                   -ArgumentList $upsServer, $upaName, $creds.Farm `
                   -Credential $creds.Setup -Authentication Credssp
    }
    Remove-Item -Path $certPath -Confirm:$false | Out-Null
    Remove-Item -Path $certificatePath -Confirm:$false | Out-Null

    Write-Verbose -Message "$time : Customer Tweaks Complete"
}
catch {
    Write-Host "OOOPS! We failed during Final Tasks." -ForegroundColor Red
    $_
    Pause
}

#endregion CUSTOMER_TWEAKS
#>

#region CDB_UPGRADE
If ($Upgrade) {
    Write-Output "$time : Upgrading Content Databases..."
    Get-SPContentDatabase | Upgrade-SPContentDatabase -Confirm:$false
    Write-Output "$time : All content databases upgraded!"
}
#endregion

#region B2B_UPGRADE
# note: finally resolved in recent 2016 PU!!!!
If ($Upgrade) {
    Write-Output "$time : Upgrading (B2B) servers in the farm..."
    ForEach ($server in $farmServers.Keys) {
        if ($farmServers.Item($server) -ne "Wac") {
            Invoke-Command -ComputerName $server -filePath $upgradeScript `
                           -ArgumentList $debug `
                           -Credential $creds.Setup -Authentication Credssp
        }
    }
    Write-Output "$time : All servers upgraded!"
}
#endregion

#region FINAL_TASKS
try {
    Write-Output "$time : Initiating all Health Analysis Jobs..."
    Get-SPTimerJob | Where-Object {$_.Title -like "Health Analysis Job*"} | Start-SPTimerJob
    Write-Host "$time : Farm Build Complete" -ForegroundColor Green
    Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * *" -ForegroundColor DarkMagenta
    Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * *" -ForegroundColor DarkMagenta
    Write-Host "* * * * * * * T H A N K S   F O R * * * * * * * * * *" -ForegroundColor DarkMagenta
    Write-Host "* * * * * U S I N G   S P E N C E ' S * * * * * * * *" -ForegroundColor DarkMagenta
    Write-Host "* * * * * * * * * S C R I P T * * * * * * * * * * * *" -ForegroundColor DarkMagenta
    Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * *" -ForegroundColor DarkMagenta
    Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * *" -ForegroundColor DarkMagenta
}
catch {
    Write-Host "OOOPS! We failed during Final Tasks." -ForegroundColor Red
    $_
    Pause
}
#endregion FINAL_TASKS

#EOF