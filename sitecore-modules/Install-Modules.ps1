param (
    [string] $AssetsPath,
    [string] $SCWDPModulePath,
    [string] $SitecoreAzureToolKitPackageName,
    [psobject[]] $SitecoreModules,
    [string] $WebRoot,
    [string] $SiteName,
    [string] $DatabasePrefix,
    [string] $SqlServer,
    [string] $SqlAdminUser,
    [string] $SqlAdminPassword,
    [string] $SolrCorePrefix,
    [string] $SolrRoot,
    [string] $SolrUrl,
    [string] $SolrService,
    [string] $SitecoreAdminPassword,
    [string] $LogsPath
)

#### Verify Sitecore Azure Toolkit package
$SitecoreAzureToolKitPackage = Get-Item -Path "$($AssetsPath)\$($SitecoreAzureToolKitPackageName)"
If ($null -eq $SitecoreAzureToolKitPackage) {
    throw "Could not find $($SitecoreAzureToolKitPackageName)"
}

#### Extract Sitecore Azure Toolkit package
Expand-Archive -Path "$($SitecoreAzureToolKitPackage.FullName)" -DestinationPath "$($SCWDPModulePath)\SitecoreAzureToolkit" -Force

#### Import Sitecore Azure Toolkit tool
$azToolkitTool = Join-Path -Path "$($SCWDPModulePath)\SitecoreAzureToolkit" -ChildPath "tools\Sitecore.Cloud.Cmdlets.dll"

Import-Module $azToolkitTool -Force

#### Install Modules
$SitecoreModules | ForEach-Object {
    $ModuleName = $_.ModuleName
    $ModulePath = Get-Item -Path "$($_.ModulePath)"

    If ($null -eq $ModulePath) {
        throw "Could not find $($ModuleName)"
    }

    Write-Host "Converting to SCWDP package..................." -ForegroundColor Green
    $scwdpPackage = Join-Path -Path "$($SCWDPModulePath)" -ChildPath $ModulePath.Name.Replace("zip", "scwdp.zip")

    If (-not (Test-Path -Path "$($scwdpPackage)")) {
        # https://coveoticore.wordpress.com/2019/06/03/how-to-install-a-wdp-in-a-sitecore-9-1-on-premises-instance/amp/
        ConvertTo-SCModuleWebDeployPackage -Path $ModulePath.FullName -Destination "$($SCWDPModulePath)" -Force -DisableDacPacOptions "*"
    }
    
    Write-Host "Installing Module: $($ModuleName)..................." -ForegroundColor Green
    $params = @{
        Path                = Resolve-Path "$($PSScriptRoot)\SIFs\install-module.json"
        Package             = "$($scwdpPackage)"
        SiteName            = $SiteName
        DatabasePrefix      = $DatabasePrefix
        SqlAdminUser        = $SqlAdminUser
        SqlAdminPassword    = $SqlAdminPassword
        SqlServer           = $SqlServer
        ModuleDatabase      = $_.ModuleDatabase
    }

    Install-SitecoreConfiguration @params *>&1 | Tee-Object "$($LogsPath)\Install-Module-$($ModuleName).log"

    If ($_.IsSxA -or ($true -eq $_.IsSxA)) {
        $params = @{
            Path = (Resolve-Path -Path "$($PSScriptRoot)\SIFs\configure-search-indexes.json")
            PhysicalPath = (Resolve-Path -Path "$($WebRoot)\$($SiteName)")
            SolrCorePrefix = $SolrCorePrefix
        }

        Install-SitecoreConfiguration @params *>&1 | Tee-Object "$($LogsPath)\Configure-SXA-Search-Indexes.log"

        $params = @{
            Path = (Resolve-Path -Path "$($PSScriptRoot)\SIFs\sxa-solr.json")
            SolrRoot = "$($SolrRoot)"
            CorePrefix = $SolrCorePrefix
            SolrUrl = $SolrUrl
            SolrService = $SolrService
            SiteName = $SiteName
            SitecoreAdminPassword = $SitecoreAdminPassword
            SolrConfigJson = (Resolve-Path -Path "$($PSScriptRoot)\SIFs\sxa-solr-config.json")
        }

        Install-SitecoreConfiguration @params *>&1 | Tee-Object "$($LogsPath)\Configure-SXA-Solr.log"
    }

}