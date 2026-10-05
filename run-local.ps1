Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  STARTING MEETING ROOM BOOKING SYSTEM LOCALLY" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

$scriptRoot = $PSScriptRoot
$tomcatDir = Join-Path $scriptRoot "tomcat"
$catalinaBat = Join-Path $tomcatDir "bin\catalina.bat"

if (-not (Test-Path $catalinaBat)) {
    Write-Host "[ERROR] Tomcat not found at $tomcatDir" -ForegroundColor Red
    exit 1
}

# Auto-detect and set JAVA_HOME if not set
if (-not $env:JAVA_HOME -or -not (Test-Path $env:JAVA_HOME)) {
    $possibleJdks = Get-ChildItem "C:\Program Files\Java" -Filter "jdk*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    if ($possibleJdks -and $possibleJdks.Count -gt 0) {
        $env:JAVA_HOME = $possibleJdks[0].FullName
        Write-Host "[INFO] Detected JAVA_HOME: $env:JAVA_HOME" -ForegroundColor DarkCyan
    } else {
        Write-Host "[WARNING] JAVA_HOME could not be auto-detected. Please ensure Java is installed." -ForegroundColor Yellow
    }
}

$env:CATALINA_HOME = $tomcatDir
$env:CATALINA_BASE = $tomcatDir

# 1. Build and package latest classes and WAR
Write-Host "[1/4] Building latest classes and WAR package..." -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File "$scriptRoot\build.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed." -ForegroundColor Red
    exit 1
}

# 2. Deploy directly as exploded ROOT webapp
Write-Host "[2/4] Deploying to local Tomcat webapps/ROOT..." -ForegroundColor Yellow
$webappsDir = Join-Path $tomcatDir "webapps"
$rootFolder = Join-Path $webappsDir "ROOT"
$rootWar = Join-Path $webappsDir "ROOT.war"

if (Test-Path $rootWar) { Remove-Item -Force $rootWar -ErrorAction SilentlyContinue }
if (Test-Path $rootFolder) { Remove-Item -Recurse -Force $rootFolder -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $rootFolder -Force | Out-Null

# Copy webapp contents into ROOT directory
Copy-Item -Path "$scriptRoot\src\main\webapp\*" -Destination $rootFolder -Recurse -Force
# Also copy WAR
Copy-Item -Path "$scriptRoot\target\meetingroom.war" -Destination $rootWar -Force

# 3. Inform user about database configuration
Write-Host "[3/4] Database Configuration:" -ForegroundColor Yellow
if (Test-Path "$scriptRoot\db.env") {
    Write-Host "      Loaded from: db.env" -ForegroundColor Green
} else {
    Write-Host "      Using system Environment Variables or defaults" -ForegroundColor DarkGray
}

Write-Host "[4/4] Starting Apache Tomcat on http://localhost:8080..." -ForegroundColor Green
Write-Host "      Press Ctrl+C in this window to stop the server." -ForegroundColor DarkYellow
Write-Host "===================================================" -ForegroundColor Cyan

# Start browser after 3 seconds in background
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 3
    Start-Process "http://localhost:8080"
} | Out-Null

# Run Tomcat in foreground
Set-Location $tomcatDir
& "$catalinaBat" run
Set-Location $scriptRoot
