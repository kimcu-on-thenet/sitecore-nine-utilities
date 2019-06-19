. "$($PSScriptRoot)\xp0-configuration.ps1"

$SitecoreCommercePackage = Join-Path -Path "$($AssetsPath)" -ChildPath "Sitecore.Commerce.2019.04-3.0.163.zip"
$CommerceAssetsPath = Join-Path -Path "$($AssetsPath)" -ChildPath "Sitecore-XC"
If (Test-Path -Path "$($CommerceAssetsPath)"){
    Remove-Item -Path "$($CommerceAssetsPath)" -Force -Recurse
}
New-Item -Path "$($CommerceAssetsPath)" -ItemType Directory | Out-Null
$SitecoreCommerceAssetsPath = Resolve-Path -Path $CommerceAssetsPath

###########
$MergeToolNuget = "msbuild.microsoft.visualstudio.web.targets.14.0.0.3.nupkg"
$MergeToolZipPackage = Join-Path -Path "$($AssetsPath)" -ChildPath "$($MergeToolNuget).zip"
If (-not (Test-Path -Path "$($MergeToolZipPackage)")) {
    $MergeToolNugetPackage = Join-Path -Path "$($AssetsPath)" -ChildPath "$($MergeToolNuget)"
    If (-not (Test-Path -Path "$($MergeToolNugetPackage)")) {
        throw "Could not find $($MergeToolNugetPackage)"
    }
    Rename-Item -Path $MergeToolNugetPackage -NewName "$($MergeToolNuget).zip"
}

Expand-Archive -Path $MergeToolZipPackage -DestinationPath "$($SitecoreCommerceAssetsPath)\$($MergeToolNuget)" -Force

Expand-Archive -Path "$($SitecoreCommercePackage)" -DestinationPath "$($CommerceAssetsPath)" -Force

$SitecoreCommerceEngineSDKZip = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore.Commerce.Engine.SDK.*.zip"
$SitecoreCommerceEngineSDK = $SitecoreCommerceEngineSDKZip.FullName.Replace(".zip", "")
If (-not (Test-Path -Path "$($SitecoreCommerceEngineSDK)")){
    Expand-Archive -Path "$($SitecoreCommerceEngineSDKZip.FullName)" -DestinationPath "$($SitecoreCommerceEngineSDK)" -Force
}
###########

$SitecoreCommerceSite = "sxa.storefront.com"

$CommerceSearchProvider = "SOLR"
$CommerceEnginePostFix = "engine.local"
$CommerceEngineCertificateName = "$($SitecoreSitePrefix)_wildcart.$($CommerceEnginePostFix)"

$CommerceOps = "$($SitecoreSitePrefix)_CommerceOps.$($CommerceEnginePostFix)"
$CommerceShops = "$($SitecoreSitePrefix)_CommerceShops.$($CommerceEnginePostFix)"
$CommerceAuthoring = "$($SitecoreSitePrefix)_CommerceAuthoring.$($CommerceEnginePostFix)"
$CommerceMinions = "$($SitecoreSitePrefix)_CommerceMinions.$($CommerceEnginePostFix)"
$BizFxSiteName = "$($SitecoreSitePrefix)_bizfx.$($CommerceEnginePostFix)"


## Package Path
$CommerceEngineDacPac = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore.Commerce.Engine.SDK.*\Sitecore.Commerce.Engine.DB.dacpac"
$SitecoreCommerceEngineZip = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore.Commerce.Engine.3*.zip"
$SitecoreBizFxZip = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore.BizFX.2.0.3*.zip"
$SitecoreCommerceHabitatImagesZip = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore.Commerce.Habitat.Images-*.zip"
$SitecoreCommerceAdventureWorksImagesZip = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Adventure Works Images.zip"

$SXACommerceModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce Experience Accelerator 2.*.zip"
$SXAStorefrontModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce Experience Accelerator Storefront 2.*.zip"
$SXAStorefrontThemeModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce Experience Accelerator Storefront Themes 2.*.zip"
$SXAStorefrontCatalogModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce Experience Accelerator Habitat Catalog*.zip"

$PowerShellExtensionsModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore PowerShell Extensions-4.7.2*.zip"
$SXAModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Experience Accelerator 1.8.1 rev. 190319 for 9.1.1*.zip"

$CommerceConnectModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce Connect*.zip"
$CommercexProfilesModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce ExperienceProfile Core*.zip"
$CommercexAnalyticsModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce ExperienceAnalytics Core*.zip"
$CommerceMAModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce Marketing Automation Core*.zip"
$CommerceMAForAutomationEngineModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce Marketing Automation for AutomationEngine*.zip"
$CEConnectModuleFullPath = Get-Item -Path "$($SitecoreCommerceAssetsPath)\Sitecore Commerce Engine Connect*.zip"


$MergeToolFullPath = "$($SitecoreCommerceAssetsPath)\$($MergeToolNuget)\tools\VSToolsPath\Web\Microsoft.Web.XmlTransform.dll"

$BraintreeAccount = @{
    MerchantId = ''
    PublicKey  = ''
    PrivateKey = ''
}

$SitecoreXCUtilityPages = Resolve-Path -Path "$($PSScriptRoot)\xc\SiteUtilityPages"
$BaseConfigurationFolder = Resolve-Path -Path "$($PSScriptRoot)\xc\Configuration"
$SitecoreXCIdentityServerConfig = Resolve-Path -Path "$($PSScriptRoot)\xc\IdentityServer"
$SolrSchemas = Resolve-Path -Path "$($PSScriptRoot)\xc\SolrSchemas"


$SitecoreXCParams = @{
    Path                                        = "$($BaseConfigurationFolder)\Commerce\Master_SingleServer.json"
	BaseConfigurationFolder                     = "$($BaseConfigurationFolder)"
    SiteName                                    = $SitecoreSite
    SiteHostHeaderName                          = $SitecoreCommerceSite
    InstallDir                                  = "$($WebRoot)\$($SitecoreSite)"
    XConnectInstallDir                          = "$($WebRoot)\$($SitecoreXConnect)"
    CommerceInstallRoot                         = "$($WebRoot)"
    CommerceServicesDbServer                    = $SqlServerHostName    
    CommerceServicesDbName                      = "$($SitecoreSitePrefix)_SharedEnvironments"
    CommerceServicesGlobalDbName                = "$($SitecoreSitePrefix)_Global"
    SitecoreDbServer                            = $SqlServerHostName         
    SitecoreCoreDbName                          = "$($SitecoreSitePrefix)_Core"
    SitecoreUsername                            = "sitecore\admin"
    SitecoreUserPassword                        = $SitecoreAdminPassword
    CommerceSearchProvider                      = $CommerceSearchProvider
    SolrUrl                                     = $SolrUrl
    SolrRoot                                    = $SolrInstallPath
    SolrService                                 = $SolrServiceName
    SolrSchemas                                 = "$($SolrSchemas)"
    CommerceServicesPostfix                     = "$($SitecoreSitePrefix)"
    CommerceServicesHostPostfix                 = "$($CommerceEnginePostFix)"
    SearchIndexPrefix                           = "$($SitecoreSitePrefix)"
    EnvironmentsPrefix                          = "Habitat"
    Environments                                = @('AdventureWorksAuthoring', 'HabitatAuthoring')
    AzureSearchServiceName                      = ""
    AzureSearchAdminKey                         = ""
    AzureSearchQueryKey                         = ""
    CommerceEngineDacPac                        = "$($CommerceEngineDacPac.FullName)"
    SitecoreCommerceEnginePath                  = "$($SitecoreCommerceEngineZip.FullName)"
    SitecoreBizFxServicesContentPath            = "$($SitecoreBizFxZip.FullName)"
    CommerceEngineCertificateName               = "$($CommerceEngineCertificateName)"
    CertPath                                    = "$($CertifcatePath)"
    ExportPassword                              = $CertExportPassword
    RootCertFileName                            = $CertRootName
    SiteUtilitiesSrc                            = "$($SitecoreXCUtilityPages)"
    HabitatImagesModuleFullPath                 = "$($SitecoreCommerceHabitatImagesZip.FullName)"
    AdvImagesModuleFullPath                     = "$($SitecoreCommerceAdventureWorksImagesZip.FullName)"
    CommerceConnectModuleFullPath               = "$($CommerceConnectModuleFullPath.FullName)"
    CommercexProfilesModuleFullPath             = "$($CommercexProfilesModuleFullPath.FullName)"
    CommercexAnalyticsModuleFullPath            = "$($CommercexAnalyticsModuleFullPath.FullName)"
    CommerceMAModuleFullPath                    = "$($CommerceMAModuleFullPath.FullName)"
    CommerceMAForAutomationEngineModuleFullPath = "$($CommerceMAForAutomationEngineModuleFullPath.FullName)"
    CEConnectModuleFullPath                     = "$($CEConnectModuleFullPath.FullName)"
    SXACommerceModuleFullPath                   = "$($SXACommerceModuleFullPath.FullName)"
    SXAStorefrontModuleFullPath                 = "$($SXAStorefrontModuleFullPath.FullName)"
    SXAStorefrontThemeModuleFullPath            = "$($SXAStorefrontThemeModuleFullPath.FullName)"
    SXAStorefrontCatalogModuleFullPath          = "$($SXAStorefrontCatalogModuleFullPath.FullName)"
    MergeToolFullPath                           = "$($MergeToolFullPath)"
    BraintreeAccount                            = $BraintreeAccount
    SitecoreBizFxServerName                     = $BizFxSiteName
    SitecoreIdentityServerApplicationName       = $SitecoreIdentityServer
    SitecoreIdentityServerHostName              = $SitecoreIdentityServer
    SqlAdminUser                                = $SqlAdminUser
    SqlAdminPassword                            = $SqlAdminPassword
    CommerceAuthoring                           = $CommerceAuthoring
    CommerceOps                                 = $CommerceOps
    CommerceShops                               = $CommerceShops
    CommerceMinions                             = $CommerceMinions
    SitecoreXCIdentityServerConfig              = $SitecoreXCIdentityServerConfig
}