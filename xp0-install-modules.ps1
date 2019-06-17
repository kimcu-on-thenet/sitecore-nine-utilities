$ErrorActionPreference = "STOP"

. "$($PSScriptRoot)\xp0-configuration.ps1"

If (-not (Test-Path -Path "$($SCWDPModulePath)")) {
    New-Item -Path "$($SCWDPModulePath)" -ItemType Directory | Out-Null
}

& "$($PSScriptRoot)\sitecore-modules\Install-Modules.ps1" -AssetsPath $AssetsPath -SCWDPModulePath $SCWDPModulePath `
                                                          -SitecoreAzureToolKitPackageName $SitecoreAzureToolKitPackageName `
                                                          -SitecoreModules $SitecoreModules -WebRoot $WebRoot -SiteName $SitecoreSite `
                                                          -DatabasePrefix $SitecoreSitePrefix `
                                                          -SqlServer $SqlServerHostName -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword `
                                                          -SolrCorePrefix $SitecoreSitePrefix -SolrRoot $SolrInstallPath -SolrUrl $SolrUrl -SolrService $SolrServiceName `
                                                          -SitecoreAdminPassword $SitecoreAdminPassword -LogsPath $LogsPath