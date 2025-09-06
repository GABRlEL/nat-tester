Write-Host "Teredo Setup and Startup Script by 2degreesGlaceon_. For support, please add '2degreesglaceonwx_' on Discord."

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Script is restarting with Administrator privileges..." -ForegroundColor Yellow

    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""

    exit
}

Write-Host "Script is running with Administrator privileges." -ForegroundColor Green

netsh interface teredo set state type=enterpriseclient servername=win1910.ipv6.microsoft.com

Write-Host "Teredo is establishing a connection to the test server in the background... Please wait 10 seconds." -ForegroundColor Yellow

Start-Sleep -Seconds 10

$teredoStatus = netsh interface teredo show state

foreach ($line in $teredoStatus) {
    if ($line -match "NAT") {
        $highlighted = $line -replace "NAT", "***NAT***"
        Write-Host $highlighted -ForegroundColor Red
    } else {
        Write-Host $line
    }
}

Write-Host "!! NOTE !!: If the status shows 'Probe (primary server)', this may indicate that your connection is using DS-Lite or a CG-NAT. In that case, Teredo will not work." -ForegroundColor Red
Write-Host ""
Write-Host "NAT Explanation:" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan
Write-Host "1. None (global connectivity): Ideal for peer-to-peer. All connections possible." -ForegroundColor Green
Write-Host "2. Cone / Full Cone: Ideal for peer-to-peer. All connections possible. Minor restrictions may apply." -ForegroundColor Green
Write-Host "3. (Port)-Restricted: Usually only restrictions on incoming connections. Only known hosts can respond. P2P usually possible." -ForegroundColor Yellow
Write-Host "4. Symmetric: Incoming connections heavily restricted; P2P connections often problematic." -ForegroundColor Red
Write-Host ""

Write-Host ""
Write-Host "Teredo is usually only needed for testing or certain peer-to-peer applications." -ForegroundColor Yellow
Write-Host "If you don't need it anymore, disabling Teredo is recommended." -ForegroundColor Yellow
Write-Host ""

$disable = Read-Host "Do you want to disable Teredo now? (Recommended) [Y/N]"

if ($disable -match '^[Yy]$') {
    netsh interface teredo set state disabled
    Write-Host "Teredo has been disabled." -ForegroundColor Green
} else {
    Write-Host "Teredo remains enabled." -ForegroundColor Cyan
}

Read-Host "Press Enter to exit the script"
