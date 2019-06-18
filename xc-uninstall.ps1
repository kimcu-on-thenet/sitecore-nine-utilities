. "$($PSScriptRoot)\xc-configuration.ps1"

Import-Module SqlServer
Import-Module WebAdministration
Import-Module SitecoreInstallFramework


Function Write-TaskHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        [Parameter(Mandatory = $true)]
        [string]$TaskType
    )

    function StringFormat {
        param(
            [int]$length,
            [string]$value,
            [string]$prefix = '',
            [string]$postfix = '',
            [switch]$padright
        )

        # wraps string in spaces so we reduce length by two
        $length = $length - 2 #- $postfix.Length - $prefix.Length
        if ($value.Length -gt $length) {
            # Reduce to length - 4 for elipsis
            $value = $value.Substring(0, $length - 4) + '...'
        }

        $value = " $value "
        if ($padright) {
            $value = $value.PadRight($length, '*')
        }
        else {
            $value = $value.PadLeft($length, '*')
        }

        return $prefix + $value + $postfix
    }

    $actualWidth = (Get-Host).UI.RawUI.BufferSize.Width
    $width = $actualWidth - ($actualWidth % 2)
    $half = $width / 2

    $leftString = StringFormat -length $half -value $TaskName -prefix '[' -postfix ':'
    $rightString = StringFormat -length $half -value $TaskType -postfix ']' -padright

    $message = ($leftString + $rightString)
    Write-Host ''
    Write-Host $message -ForegroundColor 'Red'
}

Function Remove-Website {
    [CmdletBinding()]
    param(
        [string]$siteName		
    )

    $appCmd = "C:\windows\system32\inetsrv\appcmd.exe"
    & $appCmd delete site $siteName
}

Function Remove-AppPool {
    [CmdletBinding()]
    param(		
        [string]$appPoolName
    )

    $appCmd = "C:\windows\system32\inetsrv\appcmd.exe"
    & $appCmd delete apppool $appPoolName
}

#####################################################################################
#####################################################################################
#####################################################################################



#Stop Solr Service
###################################################################################################
Write-TaskHeader -TaskName "Solr Services" -TaskType "Stop"
Write-Host "Stopping solr service"
Stop-Service $SolrServiceName -Force -ErrorAction SilentlyContinue
Write-Host "Solr service stopped successfully"

#Delete solr cores
###################################################################################################
Write-TaskHeader -TaskName "Solr Services" -TaskType "Delete Cores"
Write-Host "Deleting Solr Cores"
$pathToCores = "$($SolrInstallPath)\server\solr"
$cores = @("CatalogItemsScope", "CustomersScope", "OrdersScope")

foreach ($core in $cores) {
    Remove-Item (Join-Path $pathToCores "$($SitecoreSitePrefix)_$($core)") -recurse -force -ErrorAction SilentlyContinue
}
Write-Host "Solr Cores deleted successfully"
Write-TaskHeader -TaskName "Solr Services" -TaskType "Start"
Write-Host "Starting solr service"
Start-Service $SolrServiceName  -ErrorAction SilentlyContinue
Write-Host "Solr service started successfully"

###################################################################################################
#Remove Sites and App Pools from IIS
Write-TaskHeader -TaskName "Internet Information Services" -TaskType "Remove Websites"

$Environments = @(
    "$($CommerceOps)",
    "$($CommerceShops)",
    "$($CommerceAuthoring)",
    "$($CommerceMinions)",
    "$($BizFxSiteName)"
)

foreach ($environment in $Environments) {
    $siteName = $environment
    Write-Host ("Deleting Website  {0}" -f $siteName)
    Remove-Website -siteName $siteName -ErrorAction SilentlyContinue
    Remove-AppPool -appPoolName $siteName
    Remove-Item ("$($WebRoot)\{0}" -f $siteName) -recurse -force -ErrorAction SilentlyContinue

    Write-Host ("Remove Hostname  {0}" -f $siteName)
    $SIFParams = @{
        Path            = "$($SIFHostFile)"
        HostMappingName = $siteName
    }
    
    Uninstall-SitecoreConfiguration @SIFParams *>&1 | Tee-Object "$($LogsPath)\Remove-HostName.log"
}

Write-Host ("Remove Hostname  {0}" -f $SitecoreCommerceSite)
    $SIFParams = @{
        Path            = "$($SIFHostFile)"
        HostMappingName = $SitecoreCommerceSite
    }
    
Uninstall-SitecoreConfiguration @SIFParams *>&1 | Tee-Object "$($LogsPath)\Remove-HostName.log"
###################################################################################################
Write-TaskHeader -TaskName "SQL Server" -TaskType "Drop Databases"
#Drop databases from SQL
Write-Host "Dropping databases from SQL server"
push-location
import-module SqlServer
$databases = @("Global", "SharedEnvironments")
foreach ($db in $databases) {
    $dbName = ("{0}_{1}" -f $SitecoreSitePrefix, $db)
    Write-Host $("Dropping database {0}" -f $dbName)
    $sqlCommand = $("DROP DATABASE IF EXISTS {0}" -f $dbName)
    Write-Host $("Query: $($sqlCommand)")
    invoke-sqlcmd -ServerInstance $SqlServerHostName -Username $SqlAdminUser -Password $SqlAdminPassword -Query $sqlCommand -ErrorAction SilentlyContinue
}

Write-Host "Databases dropped successfully"

###################################################################################################
Write-TaskHeader -TaskName "Certificate" -TaskType "Remove Certificates"

$ClientCertStoreLocation = "Cert:\LocalMachine\My"
$CertFriendlyNames = @("Commerce Engine SSL Certificate", "$($SitecoreCommerceSite)")


$CertFriendlyNames | ForEach-Object {
    $FriendlyName = $_
    Get-ChildItem -Path $ClientCertStoreLocation | Where-Object { $_.FriendlyName -eq $FriendlyName } | Remove-Item
}


$CertPfxFiles = @("Commerce Engine SSL Certificate.pfx", "$($SitecoreCommerceSite).crt", "$($CommerceEngineCertificateName).pfx")

$CertPfxFiles | ForEach-Object {
    $path = Join-Path -Path "$($CertifcatePath)" -ChildPath $_
    
    If (Test-Path -Path $path) {
        Write-Host "Remove certificate: $($path)"
        Remove-Item -Path $path -Force
    }
}

###################################################################################################

pop-location
Write-TaskHeader -TaskName "Uninstallation Complete" -TaskType "Uninstall Complete"