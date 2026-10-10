# Push to GitHub Utility
$gitExe = "C:\Users\chase\AppData\Local\GitHubDesktop\app-3.6.3\resources\app\git\cmd\git.exe"
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path $gitExe)) {
    $gitExe = "git"
}

Write-Host "Syncing repository with GitHub..."
& $gitExe add -A
& $gitExe commit -m "feat: complete 1-click DriveFlow web, mobile and cron setup dashboard"
& $gitExe branch -M main
Write-Host "Attempting push to origin main..."
& $gitExe push -u origin main
