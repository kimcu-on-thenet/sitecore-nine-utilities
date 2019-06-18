
. "$($PSScriptRoot)\xc-configuration.ps1"

Import-Module SqlServer
Import-Module WebAdministration
Import-Module SitecoreInstallFramework

$ErrorActionPreference = "STOP"

$global:DEPLOYMENT_DIRECTORY = Resolve-Path -Path "$($PSScriptRoot)\xc"
$modulesPath = ( Join-Path -Path $DEPLOYMENT_DIRECTORY -ChildPath "Modules" )
if ($env:PSModulePath -notlike "*$modulesPath*") {
    $p = $env:PSModulePath + ";" + $modulesPath
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
}

$MergeToolZipPackage = Join-Path -Path "$($AssetsPath)" -ChildPath "$($MergeToolNuget).zip"
If (-not (Test-Path -Path "$($MergeToolZipPackage)")) {
    $MergeToolNugetPackage = Join-Path -Path "$($AssetsPath)" -ChildPath "$($MergeToolNuget)"
    If (-not (Test-Path -Path "$($MergeToolNugetPackage)")) {
        throw "Could not find $($MergeToolNugetPackage)"
    }
    Rename-Item -Path $MergeToolNugetPackage -NewName "$($MergeToolNuget).zip"
}

Expand-Archive -Path $MergeToolZipPackage -DestinationPath "$($SitecoreCommerceAssetsPath)\$($MergeToolNuget)" -Force

$SitecoreCommerceEngineSDK = $SitecoreCommerceEngineSDKZip.FullName.Replace(".zip", "")
If (-not (Test-Path -Path "$($SitecoreCommerceEngineSDK)")){
    Expand-Archive -Path "$($SitecoreCommerceEngineSDKZip.FullName)" -DestinationPath "$($SitecoreCommerceEngineSDK)" -Force
}

if ($CommerceSearchProvider -eq "SOLR") {
    Install-SitecoreConfiguration @SitecoreXCParams -Verbose *>&1 | Tee-Object "$LogsPath\XC-Install.log"
}
elseif ($CommerceSearchProvider -eq "AZURE") {
    Install-SitecoreConfiguration @SitecoreXCParams -Skip InstallSolrCores
}