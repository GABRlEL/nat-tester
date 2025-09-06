<#
    MKWii NAT-Test mit stunclient.exe von 2degreesGlaceon_
    Prüft NAT-Typ für zufällige Ports 22000-22999
#>

param(
    [int]$TestPorts = 5,
    [string]$StunServer = "stun.l.google.com",
    [int]$StunPort = 19302
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stunClientPath = Join-Path $scriptDir "stunclient.exe"

if (-Not (Test-Path $stunClientPath)) {
    Write-Host "❌ stunclient.exe nicht gefunden im gleichen Verzeichnis wie das Skript!" -ForegroundColor Red
    return
}

$portsToTest = 22000..22999 | Get-Random -Count $TestPorts
$results = @()

Write-Host "🎮 Starte NAT-Test für Ports: $($portsToTest -join ', ')" -ForegroundColor Cyan

foreach ($port in $portsToTest) {
    Write-Host "`n=== Teste lokaler Port $port ===" -ForegroundColor Yellow
    try {
        $output = & $StunClientPath -v $StunPort $StunServer -localport $port

        $natType = "Unknown"
        $mapped  = "Unknown"

        foreach ($line in $output) {
            if ($line -match "Mapped address:\s*(.+)") {
                $mapped = $matches[1]
                Write-Host "   🌐 Öffentliche Adresse: $mapped" -ForegroundColor Cyan
            }
            if ($line -match "Binding test:\s*(.+)") {
                $binding = $matches[1]
            }
        }

        if ($mapped -ne "Unknown") {
            $localPort = ($mapped -split ":")[1]
            if ($localPort -eq $port) {
                $natType = "Open / Full Cone or Moderate / Port-Restricted"
            } else {
                $natType = "Symmetric"
            }
        } else {
            $natType = "Strict / Keine Antwort. Kann passieren bei CG-NAT Verbindungen oder durch eine Firewall."
        }

        Write-Host "   🔹 NAT-Typ: $natType" -ForegroundColor Green
        $results += [pscustomobject]@{
            LocalPort = $port
            PublicIP  = ($mapped -split ":")[0]
            PublicPort= ($mapped -split ":")[1]
            NATType   = $natType
        }
    }
    catch {
        Write-Host ('   ❌ Fehler beim Testen von Port ' + $port + ': ' + $_) -ForegroundColor Red
        $results += [pscustomobject]@{
            LocalPort = $port
            PublicIP  = "Unknown"
            PublicPort= "Unknown"
            NATType   = "Error"
        }
    }
}

Write-Host "`n=== Zusammenfassung ===" -ForegroundColor Magenta
$results | Format-Table LocalPort, PublicIP, PublicPort, NATType
Write-Host ""
Write-Host "NAT-Erklärung:" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan
Write-Host "1. Cone / Full Cone: Ideal für Peer-to-Peer. Alle Verbindungen möglich. Evtl. leichte Einschränkungen möglich." -ForegroundColor Green
Write-Host "2. (Port)-Restricted: Meist nur Einschränkungen bei eingehenden Verbindungen. Nur bekannte Hosts können antworten. P2P meistens möglich." -ForegroundColor Yellow
Write-Host "3. Symmetric (Symmetrisch): Eingehende Verbindungen stark eingeschränkt, P2P-Verbindungen oft problematisch." -ForegroundColor Red
Write-Host ""
Write-Host "`n=== Test abgeschlossen ==="
Read-Host -Prompt "Drücke Enter, um das Fenster zu schließen"
