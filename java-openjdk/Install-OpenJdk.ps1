param (
    [string] $AssetsPath            = "E:\_sitecore-repo",
    [string] $OpenJDKZipFileName    = "java-*-openjdk-*",
    [string] $InstallPath           = "C:\Dev"
)

$ErrorActionPreference = "STOP"

$OpenJdkFolderName = "OpenJdk"
$JavaHome = Join-Path -Path "$($InstallPath)" -ChildPath $OpenJdkFolderName

If (-not (Test-Path -Path "$($JavaHome)")) {
    
    ### Verify openjdk zip file has been downloaded
    $OpenJdkZip = Join-Path -Path "$($AssetsPath)" -ChildPath "$($OpenJDKZipFileName).zip"
    If (-not (Test-Path -Path $OpenJdkZip)){
        throw "Could not find OpenJdk zip at: $($OpenJdkZip)"
    }

    If (-not (Test-Path -Path $InstallPath)) {
        New-Item -Path "$($InstallPath)" -ItemType Directory | Out-Null
    }

    ### Extract openjdk zip file to destination folder
    Expand-Archive -Path "$($OpenJdkZip)" -DestinationPath $InstallPath
    Get-ChildItem -Path "$($InstallPath)" -Filter $OpenJDKZipFileName -Directory | ForEach-Object {
        Rename-Item -Path $_.FullName -NewName $OpenJdkFolderName
    }

    ### Set environment variables

    Write-Host "Setting JAVA_HOME system variable"
    & setx /M JAVA_HOME "$($JavaHome)"

    Write-Host "Updating PATH system variable"
    [Environment]::SetEnvironmentVariable('Path', "$($env:Path);%JAVA_HOME%\bin", 'Machine');

    Write-Host "OpenJDK has been installed successfully" -ForegroundColor Green
} else {
    Write-Host "OpenJDK is existing" -ForegroundColor Green
}
