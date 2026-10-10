param(
    [string]$Target = "All"
)

$baseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logFile = Join-Path $baseDir "organizer_activity.log"

function Write-ActivityLog ($message) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp] $message"
    Write-Host $entry
    try {
        Add-Content -Path $logFile -Value $entry -ErrorAction SilentlyContinue
    } catch {}
}

function Ensure-Dir ($path) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-ActivityLog "Created directory: $path"
    }
}

function Safe-Move-File ($sourcePath, $targetDir) {
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        return $false
    }
    Ensure-Dir $targetDir
    $item = Get-Item -LiteralPath $sourcePath
    $targetPath = Join-Path $targetDir $item.Name

    if (Test-Path -LiteralPath $targetPath) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
        $ext = [System.IO.Path]::GetExtension($item.Name)
        $counter = 1
        do {
            $targetPath = Join-Path $targetDir "$baseName (dup $counter)$ext"
            $counter++
        } while (Test-Path -LiteralPath $targetPath)
    }

    Move-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    Write-ActivityLog "Moved: $($item.Name) -> $targetDir"
    return $true
}

function Classify-File ($file, $rootDir) {
    $name = $file.Name.ToLower()
    $ext = $file.Extension.ToLower()

    # Taxes & Financial
    if ($name -match "(tax|w2|w-2|1099|cad|irs|roth|property tax)") {
        return "$rootDir\Financial & Taxes\Taxes"
    }
    if ($name -match "(statement|fidelity|checking|chase.*activity|balance|spending|inv\.pdf)") {
        return "$rootDir\Financial & Taxes\Statements"
    }
    if ($name -match "(receipt|order details|zelle|invoice|bill|best buy|return code)") {
        return "$rootDir\Financial & Taxes\Receipts & Invoices"
    }

    # Real Estate & Property
    if ($name -match "(copper switch|308|anna)") {
        return "$rootDir\Real Estate & Properties\308 Copper Switch"
    }
    if ($name -match "(princeton|lakeside|lot 20|arka|monument|closing disclosure|wire.*dallas|pre-approval|pre-qualification)") {
        return "$rootDir\Real Estate & Properties\Princeton - Lakeside Estates"
    }
    if ($name -match "(crestridge|cullokea|1766)") {
        return "$rootDir\Real Estate & Properties\1766 Crestridge"
    }
    if ($name -match "(buyout|deed|affidavit|seller information|residential contract|real estate)") {
        return "$rootDir\Real Estate & Properties\General Real Estate"
    }

    # Career & Employment
    if ($name -match "(resume|cv|curriculum vitae)") {
        return "$rootDir\Career & Professional\Resumes"
    }
    if ($name -match "(voe|verification of employment|offer letter|paystub|pay date|salary)") {
        return "$rootDir\Career & Professional\Employment Records"
    }

    # Vehicles
    if ($name -match "(corvette|chevy)") {
        return "$rootDir\Vehicles\Corvette"
    }
    if ($name -match "(vw|volkswagen)") {
        return "$rootDir\Vehicles\Volkswagen"
    }
    if ($name -match "(emission|carfax|vehicle|insurance|driver.*insurance|sf ins)") {
        return "$rootDir\Vehicles\Auto General"
    }

    # Tech & Certifications
    if ($name -match "(cert|cybersecurity|exam|voucher|coursera)") {
        return "$rootDir\Tech & Certifications\Certifications"
    }
    if ($name -match "(packet tracer|ccna|cisco|switch|router|\.pkt)") {
        return "$rootDir\Tech & Certifications\Networking & CCNA"
    }
    if ($name -match "(rhel|redhat|centos|linux|selinux|nfs|autofs|repo|bash)") {
        return "$rootDir\Tech & Certifications\Linux & Sysadmin"
    }
    if ($name -match "(vmware|vcp|esxi|workstation|\.ova)") {
        return "$rootDir\Tech & Certifications\Virtualization & VMware"
    }
    if ($ext -in @(".iso", ".tar.gz", ".deb", ".msi")) {
        return "$rootDir\Tech & Certifications\ISOs & Software"
    }

    # Gaming & Development
    if ($name -match "(game dev|godot|unity|game project|paper.*ronin|creating games|tekken)") {
        return "$rootDir\Gaming & Development\Game Projects & Coding"
    }
    if ($name -match "(naraka|recording|clip|dvr|nv_|\.dvr)") {
        return "$rootDir\Gaming & Development\Clips & Recordings"
    }
    if ($ext -in @(".n64", ".z64", ".sav", ".st0", ".st10", ".cue", ".gdi") -or ($ext -eq ".iso" -and $name -match "(zelda|mario|sonic|smash|kart|dragon ball|resident evil|dino crisis)")) {
        return "$rootDir\Gaming & Development\Emulators & ROMs"
    }

    # Personal & Family
    if ($name -match "(chandler|daycare|immunization|roster)") {
        return "$rootDir\Personal & Family\Chandler"
    }
    if ($name -match "(aruba|flight|hotel|vacation|passport|edcard)") {
        return "$rootDir\Personal & Family\Travel - Aruba"
    }
    if ($name -match "(license|driver.*id|physician|medical|doctor|vaccine|fishing)") {
        return "$rootDir\Personal & Family\Identity & Government"
    }
    if ($ext -in @(".mp3", ".wav", ".flac", ".ogg", ".m4a")) {
        return "$rootDir\Personal & Family\Music & Audio"
    }
    if ($ext -in @(".heic", ".jpg", ".jpeg", ".png", ".gif", ".raw") -or ($name -match "picture|photo|screenshot")) {
        return "$rootDir\Personal & Family\Photos & Videos"
    }
    if ($ext -in @(".mp4", ".mov", ".mkv", ".avi")) {
        return "$rootDir\Gaming & Development\Clips & Recordings"
    }

    return "$rootDir\Personal & Family\Personal Notes & Documents"
}

$gDriveProtected = @("Antigravity", "Colab Notebooks", "Google AI Studio", "Google Photos", "Career & Professional", "Financial & Taxes", "Gaming & Development", "Personal & Family", "Real Estate & Properties", "Tech & Certifications", "Vehicles", "desktop.ini")
$oneDriveProtected = @("Apps", "Desktop", "Documents", "Email attachments", "Google Antigravity", "Microsoft Copilot Chat Files", "Music", "Pictures", "Videos", "Personal Vault.lnk", ".849C9593-D756-4E56-8D6E-42412F2A707B", "desktop.ini", "Career & Professional", "Financial & Taxes", "Gaming & Media", "Personal & Family", "Real Estate & Properties", "Tech & Certifications")

$totalMoved = 0

# 1. Google Drive
if ($Target -eq "All" -or $Target -eq "GoogleDrive") {
    $gdrive = "g:\My Drive"
    if (Test-Path -LiteralPath $gdrive) {
        Write-ActivityLog "Scanning Google Drive ($gdrive)..."
        $looseFiles = Get-ChildItem -LiteralPath $gdrive -File | Where-Object { $gDriveProtected -notcontains $_.Name }
        foreach ($f in $looseFiles) {
            $dest = Classify-File $f $gdrive
            if (Safe-Move-File $f.FullName $dest) { $totalMoved++ }
        }
        $staging = Join-Path $gdrive "sort loose files here"
        if (Test-Path -LiteralPath $staging) {
            Get-ChildItem -LiteralPath $staging -File | ForEach-Object {
                $dest = Classify-File $_ $gdrive
                if (Safe-Move-File $_.FullName $dest) { $totalMoved++ }
            }
            if ((Get-ChildItem -LiteralPath $staging -Force).Count -eq 0) {
                Remove-Item -LiteralPath $staging -Force
                Write-ActivityLog "Removed empty staging folder from Google Drive."
            }
        }
    }
}

# 2. OneDrive
if ($Target -eq "All" -or $Target -eq "OneDrive") {
    $onedrive = "C:\Users\chase\OneDrive"
    if (Test-Path -LiteralPath $onedrive) {
        Write-ActivityLog "Scanning OneDrive ($onedrive)..."
        $looseFiles = Get-ChildItem -LiteralPath $onedrive -File | Where-Object { $oneDriveProtected -notcontains $_.Name }
        foreach ($f in $looseFiles) {
            $dest = Classify-File $f $onedrive
            if (Safe-Move-File $f.FullName $dest) { $totalMoved++ }
        }
    }
}

# 3. PC Downloads
if ($Target -eq "All" -or $Target -eq "PC") {
    $dl = "C:\Users\chase\Downloads"
    if (Test-Path -LiteralPath $dl) {
        Write-ActivityLog "Scanning Downloads ($dl)..."
        Ensure-Dir (Join-Path $dl "Installers")
        Ensure-Dir (Join-Path $dl "Games & Emulators")
        Ensure-Dir (Join-Path $dl "Documents & Work")
        Ensure-Dir (Join-Path $dl "Media & Images")

        Get-ChildItem -LiteralPath $dl -File | Where-Object { $_.Name -ne "desktop.ini" } | ForEach-Object {
            $f = $_
            $ext = $f.Extension.ToLower()
            $name = $f.Name.ToLower()

            $targetSub = ""
            if ($ext -in @(".exe", ".msi", ".appinstaller")) {
                $targetSub = "Installers"
            } elseif ($ext -in @(".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg")) {
                $targetSub = "Media & Images"
            } elseif ($ext -in @(".pdf", ".docx", ".doc", ".xlsx", ".pptx", ".csv", ".txt", ".ova")) {
                $targetSub = "Documents & Work"
            } elseif ($ext -in @(".zip", ".7z", ".rar") -or ($name -match "sonic|game|mupen|dolphin|mod")) {
                $targetSub = "Games & Emulators"
            } else {
                $targetSub = "Documents & Work"
            }

            $destPath = Join-Path $dl $targetSub
            if (Safe-Move-File $f.FullName $destPath) { $totalMoved++ }
        }
    }
}

Write-ActivityLog "Sweep complete. Total items organized: $totalMoved"
return @{
    success = $true
    target = $Target
    itemsMoved = $totalMoved
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
} | ConvertTo-Json
