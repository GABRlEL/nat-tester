Write-Host "Teredo Setup und Startup Skript von 2degreesGlaceon_. F�r Support, bitte mich auf Discord adden: '2degreesglaceonwx_'."

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Skript wird mit Administratorrechten neu gestartet..." -ForegroundColor Yellow

    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""

    exit
}

Write-Host "Skript l�uft mit Administratorrechten." -ForegroundColor Green

netsh interface teredo set state type=enterpriseclient servername=win1910.ipv6.microsoft.com

Write-Host "Teredo baut im Hintergrund eine Verbindung zu dem Test-Server auf... Bitte 10 Sekunden warten." -ForegroundColor Yellow

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

Write-Host "!! HINWEIS !!: Sollte bei Status 'Probe (primary server)' stehen, k�nnte dies an Anzeichen f�r eine DS-Lite oder einer CG-NAT in der Verbindung sein. Teredo funktioniert dann nicht." -ForegroundColor Red
Write-Host ""
Write-Host "NAT-Erkl�rung:" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan
Write-Host "1. None (global connectivity): Ideal f�r Peer-to-Peer. Alle Verbindungen m�glich." -ForegroundColor Green
Write-Host "2. Cone / Full Cone: Ideal f�r Peer-to-Peer. Alle Verbindungen m�glich. Evtl. leichte Einschr�nkungen m�glich." -ForegroundColor Green
Write-Host "3. (Port)-Restricted: Meist nur Einschr�nkungen bei eingehenden Verbindungen. Nur bekannte Hosts k�nnen antworten. P2P meistens m�glich." -ForegroundColor Yellow
Write-Host "4. Symmetric (Symmetrisch): Eingehende Verbindungen stark eingeschr�nkt, P2P-Verbindungen oft problematisch." -ForegroundColor Red
Write-Host ""

Write-Host ""
Write-Host "Teredo wird in der Regel nur f�r Tests oder bestimmte Peer-to-Peer-Anwendungen ben�tigt." -ForegroundColor Yellow
Write-Host "Wenn Sie es nicht mehr ben�tigen, wird empfohlen Teredo zu deaktivieren." -ForegroundColor Yellow
Write-Host ""

$disable = Read-Host "M�chten Sie Teredo jetzt deaktivieren? (Empfohlen) [J/N]"

if ($disable -match '^[Jj]$') {
    netsh interface teredo set state disabled
    Write-Host "Teredo wurde deaktiviert." -ForegroundColor Green
} else {
    Write-Host "Teredo bleibt aktiviert." -ForegroundColor Cyan
}

Read-Host "Dr�cken Sie Enter, um das Skript zu beenden"
