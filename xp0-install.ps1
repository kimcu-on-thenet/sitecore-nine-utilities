param (
    [switch] $WithPrequisites
)

$ErrorActionPreference = "STOP"

. "$($PSScriptRoot)\xp0-configuration.ps1"

##############################################################################################
##############################################################################################
##############################################################################################
Function Add-AppPoolMembership {
    param(
        [string] $SiteName
    )
    #Add ApplicationPoolIdentity to performance log users to avoid Sitecore log errors (https://kb.sitecore.net/articles/404548)
    
    try {
        Add-LocalGroupMember "Performance Log Users" "IIS AppPool\$($SiteName)"
        Write-Host "Added IIS AppPool\$($SiteName) to Performance Log Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($SiteName) to Performance Log Users -- user may already exist" -ForegroundColor Yellow
    }
    try {
        Add-LocalGroupMember "Performance Monitor Users" "IIS AppPool\$($SiteName)"
        Write-Host "Added IIS AppPool\$($SiteName) to Performance Monitor Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($SiteName) to Performance Monitor Users -- user may already exist" -ForegroundColor Yellow
    }
}

##############################################################################################
##############################################################################################
##############################################################################################

Write-Host "Extrack and modify Sitecore Installation Package ....................." -ForegroundColor Yellow

& "$($PSScriptRoot)\xp0\Sitecore-Preparation.ps1" -AssetsPath "$($AssetsPath)" -SitecoreXP0OnPremisePackage "$($SitecoreXP0OnPremisePackage)" `
                                                  -SitecoreExtractedPath "$($SitecoreExtractedPath)" -SitecoreSIFVersion $SitecoreSIFVersion

Import-Module SqlServer
Import-Module WebAdministration
Import-Module SitecoreInstallFramework -Force

If ($WithPrequisites) {
    $InstallParamerters = @{
        Path            = "$($SitecoreExtractedPath)\Prerequisites.json"
        TempLocation    = "$($PrerequisitesAssetFolder)"
    }

    Install-SitecoreConfiguration @InstallParamerters *>&1 | Tee-Object "$($LogsPath)\Install-XP0-Prerequisites.log"
}


Write-Host "Installing OpenJdk ....................." -ForegroundColor Yellow

& "$($PSScriptRoot)\java-openjdk\Install-OpenJdk.ps1" -AssetsPath "$($AssetsPath)" -OpenJDKZipFileName $OpenJDKZipFileName -InstallPath "$($OpenJdkInstallPath)"

Write-Host "Generating Certificates by SIF ................................." -ForegroundColor Yellow

$CertificateParams = @{
    Path                = (Resolve-Path -Path "$($SitecoreExtractedPath)\createcert.json")
    RootCertFileName    = $CertRootName
    CertificateName     = $CertPfxFileName
    CertFriendlyName    = $CertFriendlyName
    CertPath            = $CertifcatePath
    HostNamePostfix     = $SitecoreSitePostfix
    ExportPassword      = $CertExportPassword
}

Install-SitecoreConfiguration @CertificateParams *>&1 | Tee-Object "$($LogsPath)\Generate-Sitecore-Certificates.log"

Write-Host "Installing Solr and enable SSL ....................." -ForegroundColor Yellow

& "$($PSScriptRoot)\solr\Install-Solr.ps1" -AssetsPath "$($AssetsPath)" -SolrZipFileName $SolrZipFileName -NssmZipFileName $NssmZipFileName `
                                           -InstallPath "$($SolrInstallRootPath)" -SolrServiceName $SolrServiceName -SolrHostName $SolrHostName `
                                           -SolrPort $SolrPort -SolrUrl $SolrUrl -CertPfxFilePath "$($CertPfxFilePath)" `
                                           -CertExportPassword $CertExportPassword -SIFHostFile $SIFHostFile -LogsPath $LogsPath

Write-Host "Installing Sitecore Site ....................." -ForegroundColor Yellow

Install-SitecoreConfiguration @SitecoreInstallSIFParam *>&1 | Tee-Object "$($LogsPath)\Install-XP0-SingleDeveloper.log"

Add-AppPoolMembership -SiteName $SitecoreSite
Add-AppPoolMembership -SiteName $SitecoreXConnect

try {
    iisreset -stop
    iisreset -start
}
catch {
    Write-Host "Something went wrong restarting IIS again"
    iisreset -stop
    iisreset -start
}