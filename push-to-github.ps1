# =====================================================================
#           MEETROOM PRO - EASY 1-CLICK GITHUB PUSH TOOL (PowerShell)
# =====================================================================

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "          MEETROOM PRO - EASY 1-CLICK GITHUB PUSH TOOL" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verify Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Git is not installed or not in your system PATH." -ForegroundColor Red
    Write-Host "Please install Git from https://git-scm.com/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit 1
}

# 2. Check current remote
$existingRemote = (git remote get-url origin 2>$null)

if ($existingRemote) {
    Write-Host "[INFO] Currently linked GitHub remote:" -ForegroundColor Green
    Write-Host "       $existingRemote" -ForegroundColor White
    $useExisting = Read-Host "Do you want to push to this remote? (Y/N, default: Y)"
    if ($useExisting -match "^[Nn]") {
        $existingRemote = $null
    }
}

# 3. Prompt for URL if not set
if (-not $existingRemote) {
    Write-Host ""
    Write-Host "Please paste your GitHub repository URL below." -ForegroundColor Yellow
    Write-Host "(Example: https://github.com/your-username/meeting-room-system.git)" -ForegroundColor Gray
    $repoUrl = Read-Host "Enter GitHub URL"
    
    if ([string]::IsNullOrWhiteSpace($repoUrl)) {
        Write-Host "[ERROR] No repository URL was entered. Aborting." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit 1
    }

    git remote remove origin 2>$null
    git remote add origin $repoUrl.Trim()
    Write-Host "[OK] Linked to: $($repoUrl.Trim())" -ForegroundColor Green
}

# 4. Set branch to main
Write-Host ""
Write-Host "[1/3] Setting branch to 'main'..." -ForegroundColor Yellow
git branch -M main

# 5. Commit any uncommitted files
Write-Host "[2/3] Checking for uncommitted files..." -ForegroundColor Yellow
git add -A
$hasChanges = (git status --porcelain)
if ($hasChanges) {
    git commit -m "Update Meeting Room Booking System - Latest Features"
    Write-Host "[OK] Committed latest changes." -ForegroundColor Green
} else {
    Write-Host "[OK] Working tree clean, everything already committed." -ForegroundColor Green
}

# 6. Push to GitHub
Write-Host ""
Write-Host "[3/3] Uploading code to GitHub (git push -u origin main)..." -ForegroundColor Yellow
Write-Host ""

git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] Your website code has been pushed to GitHub successfully!" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Check your GitHub repository to see all files and photos." -ForegroundColor White
    Write-Host "2. Go to https://render.com -> New + -> Web Service." -ForegroundColor White
    Write-Host "3. Connect your repository to get your 24/7 public link!" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Red
    Write-Host "[FAILED] Git push encountered an issue." -ForegroundColor Red
    Write-Host "=====================================================================" -ForegroundColor Red
    Write-Host "Tips:" -ForegroundColor Yellow
    Write-Host "- If GitHub prompts you to authenticate, sign in via browser or personal access token." -ForegroundColor Gray
    Write-Host "- Ensure your GitHub repository was created empty (without README / .gitignore)." -ForegroundColor Gray
    Write-Host "- If files already exist remotely, run: git pull origin main --rebase" -ForegroundColor Gray
    Write-Host ""
}

Read-Host "Press Enter to finish..."
