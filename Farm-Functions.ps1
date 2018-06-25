<#
.SYNOPSIS
    Utility Functions for SP13 Farm
    

.DESCRIPTION

    spence@harbar.net
    25/06/2015

    13/02/2016: Modified for SP13 from 16 baseline
    14/02/2016: Removed pre release tracing
    24/02/2016: Added Distributed Cache Utilities
    24/02/2016: Added Search Services Utilities
    18/03/2016: Added SPSecureBinding.HostHeaderCleanUp
    
.NOTES
	File Name  : Farm-Functions.ps1
	Author     : Spencer Harbar (spence@harbar.net)
	Requires   : PowerShell Version 2.0  
.LINK
.PARAMETER File  
	The configuration file
#>

#region FUNCTIONS

function Test-Credentials {
    [CmdletBinding()]
    [OutputType([Bool])]
    Param (
        [Parameter(Position = 0, ValueFromPipeLine = $true)]
        [PSCredential]
        $credential
    )

    Begin {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $env:USERDOMAIN)
    }

    Process {
        $networkCredential = $credential.GetNetworkCredential()
        return $principalContext.ValidateCredentials($networkCredential.UserName, $networkCredential.Password)
    }

    End {
        $principalContext.Dispose()
    }
}

function Test-IsAdmin($user) {

    $isAdmin = $false
    $localAdmins = Get-CimInstance -ClassName win32_group -Filter "SID = 'S-1-5-32-544'" | Get-CimAssociatedInstance -Association win32_groupuser | Select-Object caption
    foreach ($admin in $localAdmins) {
        if ( $admin.caption.ToString() -eq $user ) {$isAdmin = $true} 
    }
    return $isAdmin
}

function Start-SearchHostController($server) {

    Write-Host "$time : Starting Search service instance on $server..."
    $ssi = Get-SPEnterpriseSearchServiceInstance -Identity $server
    Start-SPEnterpriseSearchServiceInstance -Identity $ssi

    #while (Get-SPEnterpriseSearchServiceInstance -Identity $server | ? { $_.Status -eq "Online" }) {
    #    Start-Sleep 1
    #}

    Write-Host "$time : Search Service on $server is started!" -ForegroundColor Green
}

function Start-SearchQueryAndSiteSettings($server) {

    Write-Host "$time : Starting Search Query and Site Settings service instance on $server..."
    $sqss = Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Identity $server
    Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Identity $sqss

    #while (Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Identity $server | ? { $_.Status -eq "Online" }) {
    #    Start-Sleep 1
    #}

    Write-Host "$time : Search Query And Site Settings Service on $server is started!" -ForegroundColor Green
}

function Set-DistributedCacheConfiguration($maxConnections, $timeout) {
    
    Write-Output "$time : Configuring Distributed Cache Connections and Timeout..."

    #DistributedLogonTokenCache
    $DLTC = Get-SPDistributedCacheClientSetting -ContainerType DistributedLogonTokenCache
    $DLTC.MaxConnectionsToServer = $maxConnections
    $DLTC.requestTimeout = $timeout
    $DLTC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedLogonTokenCache $DLTC

    #DistributedViewStateCache
    $DVSC = Get-SPDistributedCacheClientSetting -ContainerType DistributedViewStateCache
    $DVSC.MaxConnectionsToServer = $maxConnections
    $DVSC.requestTimeout = $timeout
    $DVSC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedViewStateCache $DVSC

    #DistributedAccessCache
    $DAC = Get-SPDistributedCacheClientSetting -ContainerType DistributedAccessCache
    $DAC.MaxConnectionsToServer = $maxConnections
    $DAC.requestTimeout = $timeout
    $DAC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedAccessCache $DAC

    #DistributedActivityFeedCache
    $DAF = Get-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedCache
    $DAF.MaxConnectionsToServer = $maxConnections
    $DAF.requestTimeout = $timeout
    $DAF.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedCache $DAF

    #DistributedActivityFeedLMTCache
    $DAFC = Get-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedLMTCache
    $DAFC.MaxConnectionsToServer = $maxConnections
    $DAFC.requestTimeout = $timeout
    $DAFC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedLMTCache $DAFC

    #DistributedBouncerCache
    $DBC = Get-SPDistributedCacheClientSetting -ContainerType DistributedBouncerCache
    $DBC.MaxConnectionsToServer = $maxConnections
    $DBC.requestTimeout = $timeout
    $DBC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedBouncerCache $DBC

    #DistributedDefaultCache
    $DDC = Get-SPDistributedCacheClientSetting -ContainerType DistributedDefaultCache
    $DDC.MaxConnectionsToServer = $maxConnections
    $DDC.requestTimeout = $timeout
    $DDC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedDefaultCache $DDC

    #DistributedSearchCache
    $DSC = Get-SPDistributedCacheClientSetting -ContainerType DistributedSearchCache
    $DSC.MaxConnectionsToServer = $maxConnections
    $DSC.requestTimeout = $timeout
    $DSC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedSearchCache $DSC

    #DistributedSecurityTrimmingCache
    $DTC = Get-SPDistributedCacheClientSetting -ContainerType DistributedSecurityTrimmingCache
    $DTC.MaxConnectionsToServer = $maxConnections
    $DTC.requestTimeout = $timeout
    $DTC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedSecurityTrimmingCache $DTC

    #DistributedServerToAppServerAccessTokenCache
    $DSTAC = Get-SPDistributedCacheClientSetting -ContainerType DistributedServerToAppServerAccessTokenCache
    $DSTAC.MaxConnectionsToServer = $maxConnections
    $DSTAC.requestTimeout = $timeout
    $DSTAC.channelOpenTimeOut = $timeout
    Set-SPDistributedCacheClientSetting -ContainerType DistributedServerToAppServerAccessTokenCache $DSTAC
    Write-Output "$time : Configured Distributed Cache Settings!"
}

function Set-DistributedCacheServiceIdentity($serviceManagedAccount) {
    
    # inline version - if setting after first DC server is added, call deploy()
    Write-Host "$time : Configuring Distributed Cache Service Account..."
    $spfarm = Get-SPFarm
    $dcService = $spfarm.Services | Where-Object {$_.Name -eq "AppFabricCachingService"}
    $dcService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
    $dcService.ProcessIdentity.ManagedAccount = $serviceManagedAccount
    $dcService.ProcessIdentity.Update() 
    # we don't call $dcService.ProcessIdentity.Deploy()
    # it won't work as there is a) likely no cache cluster on this box - expected error of CacheHostInfo is null
    # it never works in farm with more than one cache host anyway
    # ----- all this does is update the creds to be used
    # ----- it does NOT update the identity or restart services
    # ----- that needs to be dealt with seperately
    Write-Host "$time : Distributed Cache Account Updated!" -ForegroundColor Green
}

function Grant-ServiceAppPermission($app, $user, $perm, $admin) {
    $sec = $app | Get-SPServiceApplicationSecurity -Admin:$admin
    $claim = New-SPClaimsPrincipal -Identity $user -IdentityType WindowsSamAccountName
    $sec | Grant-SPObjectSecurity -Principal $claim -Rights $perm
    $app | Set-SPServiceApplicationSecurity -ObjectSecurity $sec -Admin:$admin
}

function Add-FullControlWebAppPolicy ($webApp, $user) {
    # Configures a User Policy

    # get the app to avoid any update conflicts
    $wa = Get-SPWebApplication $webApp
    $waName = $wa.DisplayName

    Write-Host "$time : Configuring Web Application Policy for $waName..."
    $policy = $wa.Policies.Add("i:0#.w|$user", $user)
    $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl) 
    $policy.PolicyRoleBindings.Add($policyRole)
    $wa.Update()

}

function Register-ObjectCacheConfig ($webApp, $cacheAdmin, $cacheUser) {
    # Configures Object Cache for a Claims Web Application
    # used to be Configure-Cache
    
    # get the app to avoid any update conflicts
    $wa = Get-SPWebApplication $webApp
    $waName = $wa.DisplayName

    # Add Web Application Policies
    Write-Output "$time : Configuring Web Application Policy for $waName..."
    
    $policy = $wa.Policies.Add("i:0#.w|$cacheAdmin", $cacheAdmin)
    $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl) 
    $policy.PolicyRoleBindings.Add($policyRole)
    $policy = $wa.Policies.Add("i:0#.w|$cacheUser", $cacheUser)
    $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead) 
    $policy.PolicyRoleBindings.Add($policyRole)

    # Configure Object Cache Properties on Web Application
    Write-Output "$time : Configuring Object Cache for $waName..."
    $wa.Properties["portalsuperuseraccount"] = "i:0#.w|$cacheAdmin"
    $wa.Properties["portalsuperreaderaccount"] = "i:0#.w|$cacheUser"
    $wa.Update()
}

function Enable-SSSC ($webApp) {
    # Enable Self Service Site Creation on Web Application

    # get the app to avoid any update conflicts
    $wa = Get-SPWebApplication $webApp
    $waName = $wa.DisplayName

    Write-Output "$time : Enabling Self Service Site Creation on $waName..."
    #$wa = Get-SPWebApplication $oneDriveUrl
    $wa.SelfServiceSiteCreationEnabled = $true
    $wa.RequireContactForSelfServiceSiteCreation = $false
    $wa.Update()
}

function New-WebApp-AppPool ($apName, $managedAccount) {
    # Creates a new Web Application Application Pool
    # for which we don't actually have a cmdlet
    # allows for simpler and consistent Web App function

    Write-Output "$time : Creating $apName Application Pool..."
    $svc = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
    $appPool = New-Object Microsoft.SharePoint.Administration.SPApplicationPool $apName, $svc
    $appPool.CurrentIdentityType = "SpecificUser"
    $appPool.ProcessAccount = [Microsoft.SharePoint.Administration.SPProcessAccount]::LookupManagedAccount($managedAccount.Sid)
    $appPool.Provision()
    $appPool.Update($true)

}

function New-SSL-WebApp ($appPool, $waName, $hostHeader, $dbName, $dbServer) {
    # Creates a new SSL Web App using Claims Windows Negotiate
    # we use the host header "trick" to set the webroot on disc
    
    Write-Output "$time : Creating $waName Web Application..."
    $wa = New-SPWebApplication -ApplicationPool $appPool `
                               -Name $waName `
                               -HostHeader $hostHeader `
                               -DatabaseName $dbName `
                               -DatabaseServer $dbServer `
                               -Port 443 `
                               -SecureSocketsLayer:$true `
                               -AuthenticationProvider (New-SPAuthenticationProvider -DisableKerberos:$false)
                 
}

function New-WebApp ($appPool, $waName, $hostHeader, $dbName) {
    # Creates a new Web App using Claims Windows Negotiate
    # we use the host header "trick" to set the webroot on disc
    # quick add to support those doing non SSL, will replace with generic all up 

    Write-Output "$time : Creating $waName Web Application..."
    $wa = New-SPWebApplication -ApplicationPool $appPool `
                               -Name $waName `
                               -HostHeader $hostHeader `
                               -DatabaseName $dbName `
                               -DatabaseServer $dbServer `
                               -Port 80 `
                               -AuthenticationProvider (New-SPAuthenticationProvider -DisableKerberos:$false)
                 
}



function Export-SslCertificate ($waHostName, $password) {
    # Export SSL Certificates to a share

    Write-Host "$time : Exporting $waHostName SSL Certificate..."
    $filePath = $certPath + $waHostName + ".pfx"
    $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | ? { $_.FriendlyName -eq $waHostName }
    $cert | Export-PfxCertificate -FilePath $filePath -Password $password
}

function Add-FarmAdmin ($user) {
    $ca = Get-SPWebApplication -IncludeCentralAdministration | Where-Object {$_.DisplayName -eq "SharePoint Central Administration v4"}
    $caWeb = $ca.Sites[0].RootWeb
    $admins = $caWeb.SiteGroups["Farm Administrators"]
    $admins.AddUser($user, "", $user, "");
}

function Remove-FarmAdmin ($user) {
    $ca = Get-SPWebApplication -IncludeCentralAdministration | Where-Object {$_.DisplayName -eq "SharePoint Central Administration v4"}
    $caWeb = $ca.Sites[0].RootWeb
    $admins = $caWeb.SiteGroups["Farm Administrators"]
    $user = Get-SPUser $user -web $caWeb
    $admins.RemoveUser($user);
}

function Remove-SPHostHeader ($WebApp) {
    $wa = Get-SPWebApplication -Identity $WebApp
    $WaName = $wa.DisplayName
    Write-Output "$time : Removing SP Host Header on $WaName..."
    $IisSettings = $webApp.GetIisSettingsWithFallback("Default")
    $IisSettings.SecureBindings[0].HostHeader = ""
}

#endregion FUNCTIONS
#EOF