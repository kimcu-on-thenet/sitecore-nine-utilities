param (
    [string] $InstallPath = "E:\SitecoreSolr",
    [string] $NssmToolPath = "nssm-2.24",
    [string] $SolrHostName,
    [string] $SolrServiceName,
    [string] $SIFHostFile,
    [string] $LogsPath,
    [switch] $RemoveNSSM
)

If (Test-Path -Path "$($InstallPath)") {

    $NssmInstallPath = Join-Path -Path "$($InstallPath)" -ChildPath $NssmToolPath
    If (-not (Test-Path -Path $NssmInstallPath)) {
        throw "NSSM tool has NOT been installed"
    }

    $SolrInstallPath = Join-Path -Path "$($InstallPath)" -ChildPath $SolrServiceName
    If (-not (Test-Path -Path $SolrInstallPath)) {
        throw "Solr has NOT been installed"
    }

    Write-Host "Removing Solr service: $($SolrServiceName)" -ForegroundColor Green
    $service = Get-Service "$SolrServiceName" -ErrorAction SilentlyContinue
    if($service)
    {
        $nssmTool = "$($InstallPath)\$($NssmToolPath)\win64\nssm.exe"
        if ($service.Status -eq "Running")
        {
            &"$nssmTool" stop "$SolrFolderName"
        }
        &"$nssmTool" remove "$SolrServiceName" confirm
    }

    @("nssm", "java") | ForEach-Object {
        try{
            Get-Process "$($_)" | Stop-Process -Force
        }
        catch {}
    }

    If ($RemoveNSSM) {
        Remove-Item -Path $InstallPath -Force -Recurse
    } Else {
        Remove-Item -Path "$($SolrInstallPath)" -Recurse -Force
    }

    

    $SIFParam = @{
        Path            = "$($SIFHostFile)"
        HostMappingName = $SolrHostName
    }
    
    Uninstall-SitecoreConfiguration @SIFParam *>&1 | Tee-Object "$($LogsPath)\Deregister-Solr-HostName.log"

    Write-Host "Solr has been removed successfully" -ForegroundColor Green

} else {
    Write-Host "Solr has NOT been installed" -ForegroundColor Green
}