<#
.SYNOPSIS
    Configures IIS Bindings for use with SharePoint Web Applications
    

.DESCRIPTION
    Intended for SP Web Apps created using the "hostheader trick" which need the IIS bindings corrected.
    SP is ignorant of IP Address and Certificate bindings.

    This is actually in some ways a good thing, because it gives us ultimate flexibility.
    Allowing us to configure IIS correctly for any Load Balancer scheme and for any
    URL namespace.

    However if a new machine is added to the farm running SPFWAS, the bindings will need to be updated there as well.

    We deliberately do NO SHAREPOINT WORK in this script.
    This is 100% IIS
    Recommended tasks (such as removing the host header in the SPSecureBindings) are done seperately.

    THIS SCRIPT ONLY DEALS WITH SSL WEB SITES ON PORT 443 - by design.
    THIS SCRIPT ONLY DEALS WITH SSLFLAGS 0 (NO SNI) - by design.
   
      

    spence@harbar.net
    25/06/2015 - Original work created for MinRole Scenario Testing
    02/02/2016 - Modified for XXXXXXXXXXXXXXX

    14/03/2016 - Added support for non standard Certificate Friendly Names
    18/03/2016 - Added SPSecureBinding.HostHeader cleanup
    



.NOTES
	File Name  : Configure-IisBindings.ps1
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
    [String]$WebSiteName,
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=1)]
    [ValidateNotNullorEmpty()]
    [String]$WebSiteHostName,
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=2)]
    [ValidateNotNullorEmpty()]
    [String]$IpAddress,
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=3)]
    [ValidateNotNullorEmpty()]
    [String]$CertificateFriendlyName
) 
#endregion PARAMS

begin {
    Import-Module WebAdministration
    $Server = $env:COMPUTERNAME
    Write-Output "$(Get-Date -Format T) : Configuring IIS Bindings for $WebSiteName on $Server..."
}

process {
    try { 
        
        <#
        We cannot update an existing Binding's Host Header to an empty string or null
        If we remove the binding first, the web site will stop

        Therefore, we add a new (correct) IIS binding using the IP Address.
        Then we remove the original IIS binding.

        We MUST have both an IIS binding and an SSL binding (with certificate)
        This is a two fold configuration because HTTP processing takes place in User Mode, 
        whilst SSL processing is handled in Kernal Mode. This is also why different cmdlets 
        are neccessary.

        Then we add the certificate to the IIS binding, which also has some "fun".

        IIS can apply the "default" certificate to a HTTPS binding if it 
        exists on the machine. The behaviour is inconsistent across machines
            If this certificate is the right one, we do nothing.
            If it's the wrong one, we remove the SslBnding and create a new one with the
            correct certificate.

        Ensures correct configuration, no matter what!
        
****
        TODO
****

            this should be another playbook post
            think about adding SNI support (SSLFlags 1 with hostheader)
        #>

        $SslBindingPath = "IIS:\SslBindings\$ipAddress!443"
        $DesiredBindingInfo = $ipAddress + ":443:"
        $OriginalBinding = Get-WebBinding -Name $WebSiteName
        $OriginalBindingInfo = $OriginalBinding.bindingInformation
        $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My" | 
                                     Where-Object { $_.FriendlyName -eq $CertificateFriendlyName }

        #IP Adddress available on this box?
        If (Get-NetIPAddress | Where-Object {$_.IPAddress -eq $IpAddress}) {

            # IIS Binding
            If ($OriginalBindingInfo -eq $DesiredBindingInfo) {
                # We have the correct IIS binding, but there may not be a SSL binding.
                Write-Output "$(Get-Date -Format T) : Correct IIS Binding already exists."
            } 
            Else {
                # Add the correct IIS binding.
                Write-Output "$(Get-Date -Format T) : Adding correct IIS Binding..."
                New-WebBinding -Name $WebSiteName -IPAddress $IpAddress -Port 443 -Protocol https
                # Remove the original binding (i.e. the one created by SharePoint)
                Write-Output "$(Get-Date -Format T) : Removing original IIS Binding..."
                Remove-WebBinding -Name $WebSiteName -BindingInformation $OriginalBindingInfo
            }

            # SSL Binding and Certificate
            If ($Certificate -eq $null) {
                # no cert installed on the box, bail without making any changes
                Throw "Certificate with friendly name $CertificateFriendlyName not installed on $server!"
            }
            Else {
                # get the SSL Binding (if any)
                $SslBinding = Get-Item -Path $SslBindingPath -ErrorAction SilentlyContinue
                If ($SslBinding -eq $null) {
                    # no SSL binding, create it
                    Write-Output "$(Get-Date -Format T) : Adding new SSL Binding and Certificate..."
                    New-Item -Path $SslBindingPath -Value $Certificate -SslFlags 0 | Out-Null
                }
                Else {
                    # a SSL binding exists
                    If ($SslBinding.Thumbprint -ne $Certificate.Thumbprint) {
                        # the wrong Certificate is applied to the binding
                        # we can't update the binding so we remove it, and recreate it with the correct cert
                        Write-Output "$(Get-Date -Format T) : Incorrect Certificate is applied."
                        Write-Output "$(Get-Date -Format T) : Removing SSL binding..."
                        Remove-Item -Path $SslBindingPath
                        Write-Output "$(Get-Date -Format T) : Adding correct SSL Binding and Certificate..."
                        New-Item -Path $SslBindingPath -Value $Certificate -SslFlags 0 | Out-Null
                    }
                    Else {
                        # the right certificate is applied to the binding, no work
                        Write-Output "$(Get-Date -Format T) : Correct Certificate already applied."
                    }            
                }   
             }
         }
        Else {
            Throw "IP Address $IpAddress not bound to any adaptors on $server!"
        }
    }
    catch {
        Write-Host "OOOPS! We failed during configuration of IIS Bindings for $WebSiteName on $Server." -ForegroundColor Red
        $_
        Exit
    }
}

end {
    Write-Output "$(Get-Date -Format T) : Configured IIS Bindings for $WebSiteName on $Server!"
}
#EOF
