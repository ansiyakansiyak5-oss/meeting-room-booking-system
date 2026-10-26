@echo off
setlocal enabledelayedexpansion
title Push Meeting Room System to GitHub

echo =====================================================================
echo           MEETROOM PRO - EASY 1-CLICK GITHUB PUSH TOOL
echo =====================================================================
echo.

:: 1. Verify Git is installed
where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Git is not installed or not in your system PATH.
    echo Please install Git from https://git-scm.com/
    echo.
    pause
    exit /b 1
)

:: 2. Check if a GitHub remote is already configured
set "EXISTING_REMOTE="
for /f "tokens=2" %%A in ('git remote -v 2^>nul ^| findstr "(push)"') do (
    set "EXISTING_REMOTE=%%A"
)

if defined EXISTING_REMOTE (
    echo [INFO] Currently linked GitHub remote:
    echo        !EXISTING_REMOTE!
    echo.
    set /p "CHANGE_REMOTE=Do you want to use this remote? (Y/N, default=Y): "
    if /i "!CHANGE_REMOTE!"=="N" (
        set "EXISTING_REMOTE="
    )
)

:: 3. Prompt for GitHub repository URL if not set
if not defined EXISTING_REMOTE (
    echo.
    echo Please paste your GitHub repository URL below.
    echo (Example: https://github.com/your-username/meeting-room-system.git)
    echo.
    set /p "REPO_URL=Enter GitHub URL: "
    
    if "!REPO_URL!"=="" (
        echo [ERROR] No repository URL was entered. Aborting.
        echo.
        pause
        exit /b 1
    )

    :: Configure origin
    git remote remove origin >nul 2>nul
    git remote add origin "!REPO_URL!"
    echo [OK] Configured remote origin: !REPO_URL!
)

:: 4. Ensure branch is main
echo.
echo [1/3] Setting default branch to 'main'...
git branch -M main

:: 5. Stage and commit any outstanding changes
echo [2/3] Checking for uncommitted files...
git add -A
git diff --cached --quiet
if %ERRORLEVEL% neq 0 (
    git commit -m "Update Meeting Room Booking System - Latest Features"
    echo [OK] Committed latest changes.
) else (
    echo [OK] Working tree clean, all files already committed.
)

:: 6. Push to GitHub
echo.
echo [3/3] Uploading code to GitHub (git push -u origin main)...
echo.
git push -u origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo =====================================================================
    echo [SUCCESS] Your website code has been pushed to GitHub successfully!
    echo =====================================================================
    echo.
    echo Next Steps:
    echo 1. Open your repository on GitHub to see all files and photos.
    echo 2. Go to https://render.com -^> New + -^> Web Service.
    echo 3. Choose your GitHub repository to get your 24/7 public website link!
    echo.
) else (
    echo.
    echo =====================================================================
    echo [FAILED] Git push encountered an issue.
    echo =====================================================================
    echo Common solutions:
    echo - If GitHub asks you to authenticate, sign in via browser or Personal Access Token.
    echo - Make sure your repository on GitHub was created without checking 'README', '.gitignore', or 'License'.
    echo - If the repository already had files on GitHub, run: git pull origin main --rebase
    echo.
)

pause
