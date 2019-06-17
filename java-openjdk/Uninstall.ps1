param (
    [string] $InstallPath
)

$OpenJdkFolderName = "OpenJdk"
$JavaHome = Join-Path -Path "$($InstallPath)" -ChildPath $OpenJdkFolderName

If (Test-Path -Path "$($JavaHome)") {

    try {
        Get-Process "java" | Stop-Process -Force    
    } catch {}
    

    Remove-Item -Path "$($JavaHome)" -Recurse -Force

    Write-Host "Remove JAVA_HOME system variables...." -ForegroundColor Green
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $null, 'Machine');

    Write-Host "Update PATH system variables...." -ForegroundColor Green
    $pathEnv = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $pathEnv = $pathEnv.Replace(";%JAVA_HOME%\bin","")
    [Environment]::SetEnvironmentVariable('Path', "$($pathEnv)", 'Machine')
}