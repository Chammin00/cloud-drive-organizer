# Automated Daily Google Drive Organizer
# Maintained by Antigravity

$driveRoot = "g:\My Drive"
$logFile = "g:\My Drive\Antigravity\Projects\google drive organizer\organizer_activity.log"

function Write-Log ($message) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp] $message"
    Write-Host $entry
    try {
        Add-Content -Path $logFile -Value $entry -ErrorAction SilentlyContinue
    } catch {}
}

function Ensure-Directory ($path) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Log "Created directory: $path"
    }
}

function Safe-Move ($sourcePath, $targetDir) {
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        return
    }
    Ensure-Directory $targetDir
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
    Write-Log "Moved: $($item.Name) -> $targetDir"
}

# Protected folder and file names that should never be moved from root
$protectedNames = @(
    "Antigravity",
    "Colab Notebooks",
    "Google AI Studio",
    "Google Photos",
    "Career & Professional",
    "Financial & Taxes",
    "Gaming & Development",
    "Personal & Family",
    "Real Estate & Properties",
    "Tech & Certifications",
    "Vehicles",
    "desktop.ini"
)

function Classify-File ($file) {
    $name = $file.Name.ToLower()
    $ext = $file.Extension.ToLower()

    # 1. Taxes & Financial
    if ($name -match "(tax|w2|w-2|1099|cad|irs|roth|property tax)") {
        return "$driveRoot\Financial & Taxes\Taxes"
    }
    if ($name -match "(statement|fidelity|checking|chase.*activity|balance|spending|inv\.pdf)") {
        return "$driveRoot\Financial & Taxes\Statements"
    }
    if ($name -match "(receipt|order details|zelle|invoice|bill|best buy)") {
        return "$driveRoot\Financial & Taxes\Receipts & Invoices"
    }

    # 2. Real Estate & Property
    if ($name -match "(copper switch|308|anna)") {
        return "$driveRoot\Real Estate & Properties\308 Copper Switch"
    }
    if ($name -match "(princeton|lakeside|lot 20|arka|monument|closing disclosure|wire.*dallas|pre-approval|pre-qualification)") {
        return "$driveRoot\Real Estate & Properties\Princeton - Lakeside Estates"
    }
    if ($name -match "(crestridge|cullokea|1766)") {
        return "$driveRoot\Real Estate & Properties\1766 Crestridge"
    }
    if ($name -match "(buyout|deed|affidavit|seller information|residential contract|real estate)") {
        return "$driveRoot\Real Estate & Properties\General Real Estate"
    }

    # 3. Career & Employment
    if ($name -match "(resume|cv|curriculum vitae)") {
        return "$driveRoot\Career & Professional\Resumes"
    }
    if ($name -match "(voe|verification of employment|offer letter|paystub|pay date|salary)") {
        return "$driveRoot\Career & Professional\Employment Records"
    }

    # 4. Vehicles
    if ($name -match "(corvette|chevy)") {
        return "$driveRoot\Vehicles\Corvette"
    }
    if ($name -match "(vw|volkswagen)") {
        return "$driveRoot\Vehicles\Volkswagen"
    }
    if ($name -match "(emission|carfax|vehicle|insurance|driver.*insurance)") {
        return "$driveRoot\Vehicles\Auto General"
    }

    # 5. Tech & Certifications
    if ($name -match "(cert|cybersecurity|exam|voucher|coursera)") {
        return "$driveRoot\Tech & Certifications\Certifications"
    }
    if ($name -match "(packet tracer|ccna|cisco|switch|router|\.pkt)") {
        return "$driveRoot\Tech & Certifications\Networking & CCNA"
    }
    if ($name -match "(rhel|redhat|centos|linux|selinux|nfs|autofs|repo|bash)") {
        return "$driveRoot\Tech & Certifications\Linux & Sysadmin"
    }
    if ($name -match "(vmware|vcp|esxi|workstation|\.ova)") {
        return "$driveRoot\Tech & Certifications\Virtualization & VMware"
    }
    if ($ext -in @(".iso", ".tar.gz", ".deb", ".msi")) {
        return "$driveRoot\Tech & Certifications\ISOs & Software"
    }

    # 6. Gaming & Development
    if ($name -match "(game dev|godot|unity|game project|paper.*ronin|creating games)") {
        return "$driveRoot\Gaming & Development\Game Projects & Coding"
    }
    if ($name -match "(naraka|recording|clip|dvr|nv_|\.dvr)") {
        return "$driveRoot\Gaming & Development\Clips & Recordings"
    }
    if ($ext -in @(".n64", ".z64", ".sav", ".st0", ".st10", ".cue", ".gdi") -or ($ext -eq ".iso" -and $name -match "(zelda|mario|sonic|smash|kart|dragon ball|resident evil|dino crisis)")) {
        return "$driveRoot\Gaming & Development\Emulators & ROMs"
    }

    # 7. Personal & Family
    if ($name -match "(chandler|daycare|immunization|roster)") {
        return "$driveRoot\Personal & Family\Chandler"
    }
    if ($name -match "(aruba|flight|hotel|vacation|passport|edcard)") {
        return "$driveRoot\Personal & Family\Travel - Aruba"
    }
    if ($name -match "(license|driver.*id|physician|medical|doctor|vaccine|fishing)") {
        return "$driveRoot\Personal & Family\Identity & Government"
    }
    if ($ext -in @(".mp3", ".wav", ".flac", ".ogg", ".m4a")) {
        return "$driveRoot\Personal & Family\Music & Audio"
    }
    if ($ext -in @(".heic", ".jpg", ".jpeg", ".png", ".gif", ".raw") -or ($name -match "picture|photo|screenshot")) {
        return "$driveRoot\Personal & Family\Photos & Videos"
    }
    if ($ext -in @(".mp4", ".mov", ".mkv", ".avi")) {
        return "$driveRoot\Gaming & Development\Clips & Recordings"
    }

    # Fallback for remaining notes and documents
    return "$driveRoot\Personal & Family\Personal Notes & Documents"
}

# --- Execution ---
Write-Log "=== Starting Daily Google Drive Organization Scan ==="

# Check loose files in root
$rootFiles = Get-ChildItem -LiteralPath $driveRoot -File | Where-Object { $protectedNames -notcontains $_.Name }
$movedCount = 0

foreach ($file in $rootFiles) {
    $targetDir = Classify-File $file
    Safe-Move $file.FullName $targetDir
    $movedCount++
}

# Check staging folder if user recreated it
$stagingFolder = Join-Path $driveRoot "sort loose files here"
if (Test-Path -LiteralPath $stagingFolder) {
    Get-ChildItem -LiteralPath $stagingFolder -File | ForEach-Object {
        $targetDir = Classify-File $_
        Safe-Move $_.FullName $targetDir
        $movedCount++
    }
    if ((Get-ChildItem -LiteralPath $stagingFolder -Force).Count -eq 0) {
        Remove-Item -LiteralPath $stagingFolder -Force
        Write-Log "Removed empty staging folder."
    }
}

Write-Log "=== Scan Complete. $movedCount item(s) organized. ==="
