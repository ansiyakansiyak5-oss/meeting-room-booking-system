Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Building Meeting Room Booking System WAR" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Locate Java & JDK Tools
$javacExe = "javac"
$jarExe = "jar"

if (-not (Get-Command javac -ErrorAction SilentlyContinue) -or -not (Get-Command jar -ErrorAction SilentlyContinue)) {
    $possibleJdks = Get-ChildItem "C:\Program Files\Java" -Filter "jdk*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($jdk in $possibleJdks) {
        if (-not $env:JAVA_HOME) { $env:JAVA_HOME = $jdk.FullName }
        $candidateJavac = Join-Path $jdk.FullName "bin\javac.exe"
        $candidateJar = Join-Path $jdk.FullName "bin\jar.exe"
        if (Test-Path $candidateJavac) { $javacExe = $candidateJavac }
        if (Test-Path $candidateJar) { $jarExe = $candidateJar }
        if ((Test-Path $candidateJavac) -and (Test-Path $candidateJar)) { break }
    }
}

# 2. Create target directories
$classesDir = "src/main/webapp/WEB-INF/classes"
$targetDir = "target"
$warFile = "$PSScriptRoot/target/meetingroom.war"

if (-not (Test-Path $classesDir)) { New-Item -ItemType Directory -Path $classesDir -Force | Out-Null }
if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
if (Test-Path $warFile) { Remove-Item -Force $warFile }

# 3. Compile Java classes
Write-Host "[1/2] Compiling Java classes..." -ForegroundColor Yellow
$javaFiles = Get-ChildItem -Path "src/main/java/com/meetingroom/*.java" | ForEach-Object { $_.FullName }
$compileArgs = @("-cp", "lib/*;src/main/webapp/WEB-INF/lib/*", "-d", $classesDir) + $javaFiles
& $javacExe $compileArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 4. Package WAR using standard JDK jar.exe
Write-Host "[2/2] Packaging WAR file using jar.exe..." -ForegroundColor Yellow
$currentLocation = Get-Location
Set-Location "src/main/webapp"
& $jarExe -cvf "../../target/meetingroom.war" *
Set-Location $currentLocation

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Generated WAR: target/meetingroom.war" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Cyan
