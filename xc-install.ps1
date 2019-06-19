
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

if ($CommerceSearchProvider -eq "SOLR") {
    Install-SitecoreConfiguration @SitecoreXCParams -Verbose *>&1 | Tee-Object "$LogsPath\XC-Install.log"
}
elseif ($CommerceSearchProvider -eq "AZURE") {
    Install-SitecoreConfiguration @SitecoreXCParams -Skip InstallSolrCores
}