# DriveFlow Local HTTP Server (Zero Dependencies)
# Runs on native Windows .NET HttpListener

$port = 8080
$prefix = "http://localhost:$port/"
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $baseDir) { $baseDir = "g:\My Drive\Antigravity\Projects\google drive organizer" }
$publicDir = Join-Path $baseDir "public"
$htmlFile = Join-Path $publicDir "index.html"
$logFile = Join-Path $baseDir "organizer_activity.log"
$organizeScript = Join-Path $baseDir "scripts\organize_all.ps1"
$setupTaskScript = Join-Path $baseDir "scripts\setup_task.ps1"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "=========================================================="
    Write-Host "  DriveFlow AutoOrganizer Server Running"
    Write-Host "  Access on PC:     $prefix"
    Write-Host "  Press Ctrl+C to terminate server"
    Write-Host "=========================================================="
} catch {
    Write-Error "Failed to start HttpListener on $prefix : $_"
    exit 1
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.AbsolutePath
        $method = $request.HttpMethod

        # CORS Headers for web/mobile requests
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        if ($method -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        # 1. Serve Web / Mobile HTML UI
        if ($path -eq "/" -or $path -eq "/index.html") {
            $response.ContentType = "text/html; charset=utf-8"
            if (Test-Path -LiteralPath $htmlFile) {
                $content = [System.IO.File]::ReadAllBytes($htmlFile)
                $response.OutputStream.Write($content, 0, $content.Length)
            } else {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes("<h1>DriveFlow UI Loading...</h1>")
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            $response.Close()
            continue
        }

        # 2. API Status
        if ($path -eq "/api/status" -and $method -eq "GET") {
            $statusObj = @{
                status = "online"
                googleDrive = Test-Path "g:\My Drive"
                oneDrive = Test-Path "C:\Users\chase\OneDrive"
                downloads = Test-Path "C:\Users\chase\Downloads"
                scheduleActive = $true
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $json = $statusObj | ConvertTo-Json
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            continue
        }

        # 3. API Logs
        if ($path -eq "/api/logs" -and $method -eq "GET") {
            $logContent = ""
            if (Test-Path -LiteralPath $logFile) {
                $lines = Get-Content -LiteralPath $logFile -Tail 25 -ErrorAction SilentlyContinue
                $logContent = $lines -join "`n"
            }
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($logContent)
            $response.ContentType = "text/plain"
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            continue
        }

        # 4. API Organize (1-Click Trigger)
        if ($path -eq "/api/organize" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd()
            $target = "All"
            try {
                $bodyObj = $body | ConvertFrom-Json
                if ($bodyObj.target) { $target = $bodyObj.target }
            } catch {}

            Write-Host "Triggering organize for: $target"
            $resultJson = & powershell -ExecutionPolicy Bypass -File $organizeScript -Target $target
            
            $response.ContentType = "application/json"
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($resultJson)
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            continue
        }

        # 5. API Schedule (Setup Task / Cron)
        if ($path -eq "/api/schedule" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd()
            $time = "09:00"
            $freq = "DAILY"
            try {
                $bodyObj = $body | ConvertFrom-Json
                if ($bodyObj.time) { $time = $bodyObj.time }
                if ($bodyObj.frequency) { $freq = $bodyObj.frequency }
            } catch {}

            Write-Host "Registering schedule task: $freq at $time"
            $resultJson = & powershell -ExecutionPolicy Bypass -File $setupTaskScript -Action "register" -Time $time -Frequency $freq

            $response.ContentType = "application/json"
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($resultJson)
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            continue
        }

        # 404 Fallback
        $response.StatusCode = 404
        $response.Close()
    } catch {
        Write-Host "Request handler error: $_"
    }
}
