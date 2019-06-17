param (
    [string] $AssetsPath = "E:\_sitecore-repo",
    [string] $SolrZipFileName = "solr-7.2.1",
    [string] $NssmZipFileName = "nssm-2.24",
    [string] $InstallPath = "E:\SitecoreSolr",
    [string] $SolrServiceName,
    [string] $SolrHostName,
    [string] $SolrPort,
    [string] $SolrUrl,
    [string] $CertPfxFilePath,
    [string] $CertExportPassword,
    [string] $SIFHostFile,
    [string] $LogsPath
)

$ErrorActionPreference = "STOP"

If (-not (Test-Path -Path "$($InstallPath)")) {
    New-Item -Path "$($InstallPath)" -ItemType Directory | Out-Null
}

### Verify & extract NSSM
$NssmInstallPath = Join-Path -Path "$($InstallPath)" -ChildPath $NssmZipFileName

If (-not (Test-Path -Path "$($NssmInstallPath)")) {
    $NSSM_ZipFile = Join-Path -Path "$($AssetsPath)" -ChildPath "$($NssmZipFileName).zip"
    If (-not (Test-Path -Path "$($NSSM_ZipFile)")) {
        throw "Could not find $($NSSM_ZipFile)"
    }
    Expand-Archive -Path $NSSM_ZipFile -DestinationPath $InstallPath

    Write-Host "NSSM has been extracted successfully." -ForegroundColor Green
} else {
    Write-Host "NSSM is existing" -ForegroundColor Green
}

### Verify & Install Solr
$SolrInstallPath = Join-Path -Path "$($InstallPath)" -ChildPath $SolrServiceName

If (-not (Test-Path -Path "$($SolrInstallPath)")) {
    $SolrZipFile = Join-Path -Path "$($AssetsPath)" -ChildPath "$($SolrZipFileName).zip"

    If (-not (Test-Path -Path "$($SolrZipFile)")) {
        throw "Could not find $($SolrZipFile)"
    }

    Expand-Archive -Path $SolrZipFile -DestinationPath $InstallPath
    Rename-Item -Path "$($InstallPath)\$($SolrZipFileName)" -NewName $SolrServiceName

    Write-Host "Solr has been extracted successfully" -ForegroundColor Green
} else {
    Write-Host "Solr is existing" -ForegroundColor Green
}

### Enable SSL
$SolrCmd = Join-Path -Path "$($SolrInstallPath)" -ChildPath "bin\solr.in.cmd"
$SolrCmdBackup = "$($SolrCmd).backup"

$CertPath = Resolve-Path -Path "$($CertPfxFilePath).pfx"

If (-not (Test-Path -Path "$($SolrCmdBackup)")) {
    
    $cfg = Get-Content -Path $SolrCmd

    Rename-Item "$($SolrCmd)" "$($SolrCmdBackup)"

    $newCfg = $cfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$($CertPath)" }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM SOLR_SSL_KEY_STORE_TYPE=JKS", "SOLR_SSL_KEY_STORE_TYPE=PKCS12" }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM SOLR_SSL_TRUST_STORE_TYPE=JKS", "SOLR_SSL_TRUST_STORE_TYPE=PKCS12" }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", ('set SOLR_SSL_KEY_STORE_PASSWORD={0}' -f $CertExportPassword) }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$($CertPath)" }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", ('set SOLR_SSL_TRUST_STORE_PASSWORD={0}' -f $CertExportPassword) }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_HOST=192.168.1.1", ('set SOLR_HOST={0}' -f $SolrHostName) }; 
    $newCfg | Set-Content "$($SolrCmd)"

    Write-Host "Solr has been enabled SSL" -ForegroundColor Green
}

### Install Solr as Window Service and start
$service = Get-Service -Name $SolrServiceName -ErrorAction SilentlyContinue

### Install the service & runs
if(!($service))
{
    Write-Host "Installing Solr service"
    &"$($NssmInstallPath)\win64\nssm.exe" install "$SolrServiceName" "$SolrInstallPath\bin\solr.cmd" "-f" "-p $SolrPort"
    $service = Get-Service "$SolrServiceName" -ErrorAction SilentlyContinue
}

if($SolrServiceName.Status -ne "Running")
{
    Write-Host "Starting Solr service..."
    Start-Service "$SolrServiceName"
}
elseif ($SolrServiceName.Status -eq "Running")
{
    Write-Host "Restarting Solr service..."
    Restart-Service "$SolrServiceName"
}

### Register Host Name

$SIFParam = @{
    Path            = "$($SIFHostFile)"
    HostMappingName = $SolrHostName
}

Install-SitecoreConfiguration @SIFParam *>&1 | Tee-Object "$($LogsPath)\Register-Solr-HostName.log"

Start-Sleep -s 5
Invoke-Expression "start $($SolrUrl)"