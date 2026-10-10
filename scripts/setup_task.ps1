param(
    [string]$Action = "register",
    [string]$Time = "09:00",
    [string]$Frequency = "DAILY"
)

$taskName = "DriveFlow_AutoOrganizer"
$baseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$scriptPath = Join-Path $baseDir "scripts\organize_all.ps1"

if ($Action -eq "status") {
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        return @{
            active = $true
            taskName = $taskName
            state = "$($existing.State)"
            status = "Scheduled ($($existing.State))"
        } | ConvertTo-Json
    } else {
        return @{
            active = $false
            taskName = $taskName
            status = "Not Scheduled"
        } | ConvertTo-Json
    }
}

if ($Action -eq "unregister") {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    return @{ success = $true; message = "Task $taskName deleted." } | ConvertTo-Json
}

if ($Action -eq "register") {
    try {
        $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -Target All"
        
        $taskTrigger = $null
        if ($Frequency -eq "DAILY") {
            $taskTrigger = New-ScheduledTaskTrigger -Daily -At $Time
        } elseif ($Frequency -eq "HOURLY") {
            $taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6)
        } else {
            $taskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At $Time
        }

        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Force | Out-Null

        return @{
            success = $true
            taskName = $taskName
            frequency = $Frequency
            time = $Time
            message = "Task successfully registered in Windows Task Scheduler ($Frequency at $Time)"
        } | ConvertTo-Json
    } catch {
        return @{
            success = $false
            error = "$($_.Exception.Message)"
        } | ConvertTo-Json
    }
}
