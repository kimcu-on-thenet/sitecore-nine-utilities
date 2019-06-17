param (
    [string] $AssetsPath,
    [string] $SitecoreXP0OnPremisePackage,
    [string] $SitecoreExtractedPath,
    [string] $SitecoreSIFVersion
)

$ErrorActionPreference = "STOP"

Function Modify-SIF-createcert-json {
    param (
        [string] $CreateCertJson = "createcert.json"
    )

    $CreateCertJsonFile = Join-Path -Path "$($SitecoreExtractedPath)" -ChildPath $CreateCertJson

    $config = Get-Content -Path "$($CreateCertJsonFile)" | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json;

    ## Add parameter

    If ($null -eq $config.Parameters.'HostNamePostfix') {
        $HostNamePostfix = @{
            Type         = 'string'
            DefaultValue = ''
            Description  = 'Provide the Postfix of Hostname to generate wildcart certificate'
        }
        $config.Parameters | Add-Member -Name "HostNamePostfix" -Value $HostNamePostfix -Type NoteProperty
    }

    If ($null -eq $config.Parameters.'CertFriendlyName') {
        $CertFriendlyName = @{
            Type = "string"
            Description = "Provide the friendly name of certificate"
        }
        $config.Parameters | Add-Member -Name "CertFriendlyName" -Value $CertFriendlyName -Type NoteProperty
    }

    ## Modify task
    $config.Tasks.CreateSignedCert.Params.DnsName = @("[concat('*.', parameter('HostNamePostfix'))]", "127.0.0.1")
    
    If ($null -eq $config.Tasks.CreateSignedCert.Params.FriendlyName) {
        $config.Tasks.CreateSignedCert.Params | Add-Member -Name "FriendlyName" -Value "[parameter('CertFriendlyName')]" -Type NoteProperty
    }
    If ($null -eq $config.Tasks.CreateRootCert.Params.FriendlyName) {
        $config.Tasks.CreateRootCert.Params | Add-Member -Name "FriendlyName" -Value "[parameter('CertFriendlyName')]" -Type NoteProperty
    }

    ConvertTo-Json $config -Depth 50 | Set-Content -Path "$($CreateCertJsonFile)"
}

Function Modify-PhysicalPath {
    param (
        [string] $JsonFile
    )

    $SIFJsonFile = Join-Path -Path "$($SitecoreExtractedPath)" -ChildPath $JsonFile
    $config = Get-Content -Path "$($SIFJsonFile)" | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json;

    If ($null -eq $config.Parameters.WebRoot) {
        $WebRootParam = @{
            Type            = "string"
            DefaultValue    = "c:\inetpub\wwwroot"
            Description     =  "The physical path of the configured Web Root for the environment"
        }
        $config.Parameters | Add-Member -Name "WebRoot" -Value $WebRootParam -Type NoteProperty
    }
    
    $config.Variables.'Site.PhysicalPath' = "[joinpath(parameter('WebRoot'), parameter('SiteName'))]"
    ConvertTo-Json $config -Depth 50 | Set-Content -Path "$($SIFJsonFile)"
}

Function Modify-Sitecore-XP0-SSL {

    $SIFJsonFile = Join-Path -Path "$($SitecoreExtractedPath)" -ChildPath "sitecore-xp0.json"
    $config = Get-Content -Path "$($SIFJsonFile)" | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json;

    ### Add 'SSLCert' parameter
    If ($null -eq $config.Parameters.'SSLCert') {
        $SSLCert = @{
            Type         = 'string'
            DefaultValue = ''
            Description  = 'The certificate to use for HTTPS web bindings. Provide the name or the thumbprint. If not provided a certificate will be generated.'
        }
        $config.Parameters | Add-Member -Name "SSLCert" -Value $SSLCert -Type NoteProperty
    }

    ### Add 'Security.SSL.CertificateThumbprint' variable
    If ($null -eq $config.Variables.'Security.SSL.CertificateThumbprint') {
        $CertificateThumbprint = "[GetCertificateThumbprint(parameter('SSLCert'), 'Cert:\Localmachine\My')]"
        $config.Variables | Add-Member -Name 'Security.SSL.CertificateThumbprint' -Value $CertificateThumbprint -Type NoteProperty
    }

    ### Enable SSL binding
    $config.Tasks.CreateBindings.Params.Add = @(
        @{
            HostHeader = "[parameter('SiteName')]"
            Protocol = "https"
            SSLFlags = 1
            Thumbprint = "[variable('Security.SSL.CertificateThumbprint')]"
        })
    
    $config.Tasks.UpdateSolrSchema.Params.SitecoreInstanceRoot = "[concat('https://', parameter('DnsName'))]"

    ConvertTo-Json $config -Depth 50 | Set-Content -Path "$($SIFJsonFile)"
}

Function Modify-XP0-SingleDeveloper-Json {
    $SIFJsonFile = Join-Path -Path "$($SitecoreExtractedPath)" -ChildPath "XP0-SingleDeveloper.json"
    $config = Get-Content -Path "$($SIFJsonFile)" | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json;

    ### WebRoot
    If ($null -eq $config.Parameters.WebRoot) {
        $WebRootParam = @{
            Type            = "string"
            DefaultValue    = "c:\inetpub\wwwroot"
            Description     =  "The physical path of the configured Web Root for the environment"
        }
        $config.Parameters | Add-Member -Name "WebRoot" -Value $WebRootParam -Type NoteProperty
    }

    $WebRootReferenceParam = @{
        Type            = "string"
        Reference       = "WebRoot"
        Description     =  "The physical path of the configured Web Root for the environment"
    }
    If ($null -eq $config.Parameters.'IdentityServer:WebRoot') {
        $config.Parameters | Add-Member -Name "IdentityServer:WebRoot" -Value $WebRootReferenceParam -Type NoteProperty
    }

    If ($null -eq $config.Parameters.'XConnectXP0:WebRoot') {
        $config.Parameters | Add-Member -Name "XConnectXP0:WebRoot" -Value $WebRootReferenceParam -Type NoteProperty
    }

    If ($null -eq $config.Parameters.'SitecoreXP0:WebRoot') {
        $config.Parameters | Add-Member -Name "SitecoreXP0:WebRoot" -Value $WebRootReferenceParam -Type NoteProperty
    }

    ### Sitecore's Certificate
    If ($null -eq $config.Parameters.'XConnectXP0:SSLCert') {
        $XConnectXP0SSLCert = @{
            Type            = 'string'
            Reference       = 'XConnectCertificateName'
            Description     = 'The certificate to use for HTTPS web bindings. Provide the name or the thumbprint. If not provided a certificate will be generated.'
        }
        $config.Parameters | Add-Member -Name "XConnectXP0:SSLCert" -Value $XConnectXP0SSLCert -Type NoteProperty
    }

    If ($null -eq $config.Parameters.'SitecoreSiteCertificateName') {
        $SitecoreSiteSSLCert = @{
            Type         = 'string'
            DefaultValue = ''
            Description  = 'The certificate to use for HTTPS web bindings. Provide the name or the thumbprint. If not provided a certificate will be generated.'
        }
        $config.Parameters | Add-Member -Name "SitecoreSiteCertificateName" -Value $SitecoreSiteSSLCert -Type NoteProperty
    }

    If ($null -eq $config.Parameters.'SitecoreXP0:SSLCert') {
        $XConnectXP0SSLCert = @{
            Type            = 'string'
            Reference       = 'SitecoreSiteCertificateName'
            Description     = 'The certificate to use for HTTPS web bindings. Provide the name or the thumbprint. If not provided a certificate will be generated.'
        }
        $config.Parameters | Add-Member -Name "SitecoreXP0:SSLCert" -Value $XConnectXP0SSLCert -Type NoteProperty
    }

    ### Includes
    $RemoveNodes = @("XConnectCertificates", "IdentityServerCertificates")
    $RemoveNodes | ForEach-Object {
        $config.Includes.PSObject.Properties.Remove($_)    
    }
    $config.Includes.IdentityServer.Source = "$($SitecoreExtractedPath)\identityServer.json"
    $config.Includes.XConnectSolr.Source = "$($SitecoreExtractedPath)\xconnect-solr.json"
    $config.Includes.XConnectXP0.Source = "$($SitecoreExtractedPath)\xconnect-xp0.json"
    $config.Includes.SitecoreSolr.Source = "$($SitecoreExtractedPath)\Sitecore-solr.json"
    $config.Includes.SitecoreXP0.Source = "$($SitecoreExtractedPath)\Sitecore-XP0.json"

    ConvertTo-Json $config -Depth 50 | Set-Content -Path "$($SIFJsonFile)"
}

Function Install-SIF {
    #Register Assets PowerShell Repository
    if ((Get-PSRepository | Where-Object {$_.Name -eq "SitecoreGallery" }).count -eq 0) {
        Register-PSRepository -Name "SitecoreGallery" -SourceLocation "https://sitecore.myget.org/F/sc-powershell/api/v2" -InstallationPolicy Trusted 
    }

    $module = Get-Module -FullyQualifiedName @{ModuleName = "SitecoreInstallFramework"; ModuleVersion = $SitecoreSIFVersion }
    if (-not $module) {
        write-host "Installing the Sitecore Install Framework, version $($SitecoreSIFVersion)" -ForegroundColor Green
        Install-Module SitecoreInstallFramework -Repository "SitecoreGallery" -Scope CurrentUser -Force
    }
}

#=================================================================================================================#
#================================ |----- Executions -----|  ======================================================#
#=================================================================================================================#

### Extract Sitecore Installation Package
If (-not (Test-Path -Path "$($SitecoreXP0OnPremisePackage)")) {
    throw "Could not found $($SitecoreXP0OnPremisePackage)"
}

If (-not (Test-Path -Path "$($SitecoreExtractedPath)")) {
    New-Item -Path "$($SitecoreExtractedPath)" -ItemType Directory | Out-Null
}

Expand-Archive -Path "$($SitecoreXP0OnPremisePackage)" -DestinationPath "$($SitecoreExtractedPath)" -Force

### Extract SIF configuration; then do some modifications
$SIFConfiguration = Get-Item -Path "$($SitecoreExtractedPath)\XP0 Configuration files*" -Filter "*.zip"
Expand-Archive -Path "$($SIFConfiguration)" -DestinationPath "$($SitecoreExtractedPath)" -Force

Modify-SIF-createcert-json -CreateCertJson "createcert.json"

Modify-PhysicalPath -JsonFile "IdentityServer.json"
Modify-PhysicalPath -JsonFile "xconnect-xp0.json"
Modify-PhysicalPath -JsonFile "sitecore-xp0.json"

Modify-Sitecore-XP0-SSL

Modify-XP0-SingleDeveloper-Json

Install-SIF