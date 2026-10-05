Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Building Meeting Room Booking System WAR" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Create target directories
$classesDir = "src/main/webapp/WEB-INF/classes"
$targetDir = "target"
$warFile = "$PSScriptRoot/target/meetingroom.war"
$zipFile = "$PSScriptRoot/target/meetingroom.zip"

if (-not (Test-Path $classesDir)) { New-Item -ItemType Directory -Path $classesDir -Force | Out-Null }
if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
if (Test-Path $warFile) { Remove-Item -Force $warFile }
if (Test-Path $zipFile) { Remove-Item -Force $zipFile }

# 2. Compile Java classes
Write-Host "[1/3] Compiling Java classes..." -ForegroundColor Yellow
$compileArgs = @("-cp", "lib/*;src/main/webapp/WEB-INF/lib/*", "-d", $classesDir) + (Get-ChildItem -Path "src/main/java/com/meetingroom/*.java" | ForEach-Object { $_.FullName })
& javac $compileArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 3. Package WAR file
Write-Host "[2/3] Packaging WAR file..." -ForegroundColor Yellow
$currentLocation = Get-Location
Set-Location "src/main/webapp"

# Check if jar.exe exists, otherwise use Compress-Archive
if (Get-Command jar -ErrorAction SilentlyContinue) {
    & jar -cvf "../../target/meetingroom.war" *
} else {
    Compress-Archive -Path * -DestinationPath $zipFile -Force
    Rename-Item -Path $zipFile -NewName "meetingroom.war" -Force
}
Set-Location $currentLocation

Write-Host "[3/3] Build completed successfully!" -ForegroundColor Green
Write-Host "Generated WAR file: target/meetingroom.war" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Cyan
