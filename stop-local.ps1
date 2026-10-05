Write-Host "Stopping local Apache Tomcat..." -ForegroundColor Yellow
$scriptRoot = $PSScriptRoot
$tomcatDir = Join-Path $scriptRoot "tomcat"

if (-not $env:JAVA_HOME) {
    $possibleJdks = Get-ChildItem "C:\Program Files\Java" -Filter "jdk*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    if ($possibleJdks) { $env:JAVA_HOME = $possibleJdks[0].FullName }
}

$env:CATALINA_HOME = $tomcatDir
$env:CATALINA_BASE = $tomcatDir

& "$tomcatDir\bin\catalina.bat" stop

Write-Host "Local Tomcat server stopped." -ForegroundColor Green
