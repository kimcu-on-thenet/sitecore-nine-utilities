. "$($PSScriptRoot)\xp0-configuration.ps1"

$ErrorActionPreference = "STOP"

Import-Module SqlServer
Import-Module WebAdministration
Import-Module SitecoreInstallFramework -Force

##############################################################################################
##############################################################################################
##############################################################################################
Function Remove-AppPoolMembership {
    param (
        [string] $SiteName
    )

    try {
        Remove-LocalGroupMember "Performance Log Users" "IIS AppPool\$($SiteName)"
        Write-Host "Removed IIS AppPool\$($SiteName) from Performance Log Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't remove IIS AppPool\$($SiteName) from Performance Log Users -- user may not exist" -ForegroundColor Yellow
    }

    try {
        Remove-LocalGroupMember "Performance Monitor Users" "IIS AppPool\$($SiteName)"
        Write-Host "Removed IIS AppPool\$($SiteName) from Performance Monitor Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't remove IIS AppPool\$($SiteName) from Performance Monitor Users -- user may not exist" -ForegroundColor Yellow
    }
}

##############################################################################################
##############################################################################################
##############################################################################################

Uninstall-SitecoreConfiguration @SitecoreInstallSIFParam *>&1 | Tee-Object "$($LogsPath)\Uninstall-XP0-SingleDeveloper.log"

Remove-AppPoolMembership -SiteName $SitecoreSite
Remove-AppPoolMembership -SiteName $SitecoreXConnect

$SIFHostFile = "$($PSScriptRoot)\solr\SIFs\register-hosts.json"
& "$($PSScriptRoot)\solr\Uninstall.ps1" -InstallPath "$($SolrInstallRootPath)" -NssmToolPath $NssmZipFileName `
                                        -SolrHostName $SolrHostName -SolrServiceName $SolrServiceName -SIFHostFile $SIFHostFile `
                                        -LogsPath $LogsPath -RemoveNSSM

& "$($PSScriptRoot)\java-openjdk\Uninstall.ps1" -InstallPath "$($OpenJdkInstallPath)"

@("Cert:\LocalMachine\My", "Cert:\LocalMachine\Root") | ForEach-Object {
    Get-ChildItem -Path "$($_)" | Where-Object { $_.FriendlyName -eq $CertFriendlyName } | Remove-Item -Force
}

If (Test-Path -Path "$($CertPfxFilePath).pfx") {
    Remove-Item -Path "$($CertPfxFilePath).pfx" -Force
}

If (Test-Path -Path "$($CertRootPfxFile).pfx") {
    Remove-Item -Path "$($CertRootPfxFile).pfx" -Force
}