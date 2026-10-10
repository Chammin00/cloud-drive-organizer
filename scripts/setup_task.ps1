param(
    [string]$Action = "register", # register, unregister, status
    [string]$Time = "09:00",
    [string]$Frequency = "DAILY" # DAILY, HOURLY, WEEKLY
)

$taskName = "DriveFlow_AutoOrganizer"
$baseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$scriptPath = Join-Path $baseDir "scripts\organize_all.ps1"

if ($Action -eq "status") {
    $exists = schtasks /query /tn $taskName 2>$null
    if ($LASTEXITCODE -eq 0) {
        return @{ active = $true; taskName = $taskName; status = "Running/Scheduled" } | ConvertTo-Json
    } else {
        return @{ active = $false; taskName = $taskName; status = "Not Scheduled" } | ConvertTo-Json
    }
}

if ($Action -eq "unregister") {
    schtasks /delete /tn $taskName /f 2>$null
    return @{ success = $true; message = "Task $taskName deleted." } | ConvertTo-Json
}

if ($Action -eq "register") {
    # Unregister old if exists
    schtasks /delete /tn $taskName /f 2>$null

    # Create scheduled task running powershell with organize_all.ps1
    $command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -Target All"
    $output = schtasks /create /tn $taskName /tr "$command" /sc $Frequency /st $Time /f 2>&1

    if ($LASTEXITCODE -eq 0) {
        return @{
            success = $true
            taskName = $taskName
            frequency = $Frequency
            time = $Time
            message = "Task successfully registered to run $Frequency at $Time"
        } | ConvertTo-Json
    } else {
        return @{
            success = $false
            error = "$output"
        } | ConvertTo-Json
    }
}
