

$SitecoreSIFVersion     = "1.2.1"
$SitecoreSitePrefix     = "sc911"
$SitecoreSitePostfix    = "dev.local"

$AssetsPath             = "E:\Sitecore-Repo"
$OpenJdkInstallPath     = "C:\Dev"
$SolrInstallRootPath    = "E:\SitecoreSolr"
$WebRoot                = "E:\Inetpub\wwwroot"

$SitecoreExtractedPath      = Join-Path -Path "$($AssetsPath)" -ChildPath "Sitecore-XP0"
$PrerequisitesAssetFolder   = Join-Path -Path "$($AssetsPath)" -ChildPath "Sitecore-Prerequisites"
$SCWDPModulePath            = Join-Path -Path "$($AssetsPath)" -ChildPath "Sitecore-Packages"

$CertifcatePath         = ".\Certificates"
$LogsPath               = ".\InstallLogs"

If (-not (Test-Path -Path "$($CertifcatePath)")) {
    New-Item -Path "$($CertifcatePath)" -ItemType Directory | Out-Null
}

If (-not (Test-Path -Path "$($LogsPath)")) {
    New-Item -Path "$($LogsPath)" -ItemType Directory | Out-Null
}

If (-not (Test-Path -Path "$($PrerequisitesAssetFolder)")) {
    New-Item -Path "$($PrerequisitesAssetFolder)" -ItemType Directory | Out-Null
}

If (-not (Test-Path -Path "$($SitecoreExtractedPath)")) {
    New-Item -Path "$($SitecoreExtractedPath)" -ItemType Directory | Out-Null
}

### Installation file names
$OpenJDKZipFileName             = "java-*-openjdk-*"
$SolrZipFileName                = "solr-7.2.1"
$NssmZipFileName                = "nssm-2.24"
$SitecoreXP0OnPremisePackage    = Join-Path -Path "$($AssetsPath)" -ChildPath "Sitecore 9.1.1 rev. 002459 (WDP XP0 packages).zip"
$SitecoreLicenseFile            = Join-Path -Path "$($AssetsPath)" -ChildPath "license.xml"


### Certificate configurations
$CertRootName           = "Root_$($SitecoreSitePrefix)"
$CertRootPfxFile        = Join-Path -Path "$($CertifcatePath)" -ChildPath $CertRootName
$CertPfxFileName        = "$($SitecoreSitePrefix)_wildcart.$($SitecoreSitePostfix)"
$CertNameInCertStore    = "*.$($SitecoreSitePostfix)"
$CertFriendlyName       = "$($SitecoreSitePrefix)"
$CertPfxFilePath        = Join-Path -Path "$($CertifcatePath)" -ChildPath $CertPfxFileName
$CertExportPassword     = "$($SitecoreSitePrefix)in(2019)"

### Solr Configurations
$SolrPort = "8721"
$SolrServiceName = "Solr-$($SitecoreSitePrefix)"
$SolrInstallPath = Join-Path -Path "$($SolrInstallRootPath)" -ChildPath $SolrServiceName


### SQLServer Configurations
$SqlServerHostName = $env:COMPUTERNAME
$SqlAdminUser       = "sa"
$SqlAdminPassword   = "[update-with-your-sa-password]"

### Sitecore configurations
$SitecoreSite = "$($SitecoreSitePrefix).$($SitecoreSitePostfix)"
$SitecoreIdentityServer = "$($SitecoreSitePrefix)_identityserver.$($SitecoreSitePostfix)"
$SitecoreXConnect = "$($SitecoreSitePrefix)_xconnect.$($SitecoreSitePostfix)"
$SolrHostName = "$($SitecoreSitePrefix)_solr.$($SitecoreSitePostfix)"

$SitecoreSiteUrl = "https://$($SitecoreSite)"
$SitecoreIdentityAuthority = "https://$($SitecoreIdentityServer)"
$SitecoreXConnectSiteUrl = "https://$($SitecoreXConnect)"
$SolrUrl = "https://$($SolrHostName):$($SolrPort)/solr"

$SitecoreAdminPassword = "b"

$SitecoreIdentityServerPackage = Get-Item -Path "$($SitecoreExtractedPath)\Sitecore.IdentityServer*(OnPrem)_identityserver.scwdp.zip"
$SitecoreXConnectPackage = Get-Item -Path "$($SitecoreExtractedPath)\Sitecore*(OnPrem)_xp0xconnect.scwdp.zip"
$SitecoreSinglePackage = Get-Item -Path "$($SitecoreExtractedPath)\Sitecore*(OnPrem)_single.scwdp.zip"

$SitecoreInstallSIFParam = @{
    Path                           = "$($SitecoreExtractedPath)\XP0-SingleDeveloper.json"
    SqlServer                      = $SqlServerHostName
    SqlAdminUser                   = $SqlAdminUser
    SqlAdminPassword               = $SqlAdminPassword
    SqlCollectionPassword          = $SqlAdminPassword
    SqlReferenceDataPassword       = $SqlAdminPassword
    SqlMarketingAutomationPassword = $SqlAdminPassword
    SqlMessagingPassword           = $SqlAdminPassword
    SqlProcessingEnginePassword    = $SqlAdminPassword
    SqlReportingPassword           = $SqlAdminPassword
    SqlCorePassword                = $SqlAdminPassword
    SqlSecurityPassword            = $SqlAdminPassword
    SqlMasterPassword              = $SqlAdminPassword
    SqlWebPassword                 = $SqlAdminPassword
    SqlProcessingTasksPassword     = $SqlAdminPassword
    SqlFormsPassword               = $SqlAdminPassword
    SqlExmMasterPassword           = $SqlAdminPassword
    SitecoreAdminPassword          = $SitecoreAdminPassword
    SolrUrl                        = $SolrUrl
    SolrRoot                       = $SolrInstallPath
    SolrService                    = $SolrServiceName
    Prefix                         = $SitecoreSitePrefix
    XConnectCertificateName        = $CertNameInCertStore
    IdentityServerCertificateName  = $CertNameInCertStore
    SitecoreSiteCertificateName    = $CertNameInCertStore
    IdentityServerSiteName         = $SitecoreIdentityServer
    LicenseFile                    = $SitecoreLicenseFile
    XConnectPackage                = "$($SitecoreXConnectPackage.FullName)"
    SitecorePackage                = "$($SitecoreSinglePackage.FullName)"
    IdentityServerPackage          = "$($SitecoreIdentityServerPackage.FullName)"
    XConnectSiteName               = $SitecoreXConnect
    SitecoreSitename               = $SitecoreSite
    PasswordRecoveryUrl            = $SitecoreSiteUrl
    SitecoreIdentityAuthority      = $SitecoreIdentityAuthority
    XConnectCollectionService      = $SitecoreXConnectSiteUrl
    AllowedCorsOrigins             = $SitecoreSiteUrl
    WebRoot                        = $WebRoot
}

$SIFHostFile = "$($PSScriptRoot)\solr\SIFs\register-hosts.json"

##### Sitecore's packages
$SitecoreAzureToolKitPackageName = "Sitecore Azure Toolkit*.zip"
$SitecoreModules = @(
    @{
        ModulePath      = "$($AssetsPath)\Sitecore PowerShell Extensions-4.7.2 for Sitecore 8.zip"
        ModuleName      = "SPE-4.7.2" 
        ModuleDatabase  = "mastercore"
    },
    @{
        ModulePath      = "$($AssetsPath)\Sitecore Experience Accelerator 1.8.1 rev. 190319 for 9.1.1.zip"
        ModuleName      = "SXA-1.8.1" 
        IsSxA           = $true
        ModuleDatabase  = "mastercore"
    }
)