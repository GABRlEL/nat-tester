<#
    MKWii NAT-Test with stunclient.exe by Hi5Glaceon_ (Contact: hi5glaceon_ on Discord)
    Checks the NAT-Type for random MKWii ports at 22000-22999
#>

param(
    [int]$TestPorts = 5,
    [string]$StunServer = "stun.1und1.de",
    [int]$StunPort = 3478          
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stunClientPath = Join-Path $scriptDir "stunclient.exe"

if (-Not (Test-Path $stunClientPath)) {
    Write-Host "❌ stunclient.exe not found in the same directory as the script!" -ForegroundColor Red
    return
}

$portsToTest = 22000..22999 | Get-Random -Count $TestPorts
$results = @()

Write-Host "🎮 Starting NAT test for ports: $($portsToTest -join ', ')" -ForegroundColor Cyan
Write-Host "MKWii NAT-Test with stunclient.exe by Hi5Glaceon_ (Contact: hi5glaceon_ on Discord)" -ForegroundColor Cyan

foreach ($port in $portsToTest) {
    Write-Host "`n=== Testing local port $port ===" -ForegroundColor Yellow
    try {
        $output = & $StunClientPath -v $StunPort $StunServer -localport $port

        $natType = "Unknown"
        $mapped  = "Unknown"

        foreach ($line in $output) {
            if ($line -match "Mapped address:\s*(.+)") {
                $mapped = $matches[1]
                Write-Host "   🌐 Public IP address: $mapped" -ForegroundColor Cyan
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
            $natType = "Strict / No Answer. Can happen on CG-NAT connections or blocking firewall."
        }

        Write-Host "   🔹 NAT-Type: $natType" -ForegroundColor Green
        $results += [pscustomobject]@{
            LocalPort = $port
            PublicIP  = ($mapped -split ":")[0]
            PublicPort= ($mapped -split ":")[1]
            NATType   = $natType
        }
    }
    catch {
        Write-Host ('   ❌ Error testing port ' + $port + ': ' + $_) -ForegroundColor Red
        $results += [pscustomobject]@{
            LocalPort = $port
            PublicIP  = "Unknown"
            PublicPort= "Unknown"
            NATType   = "Error"
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Magenta
$results | Format-Table LocalPort, PublicIP, PublicPort, NATType
Write-Host ""
Write-Host "NAT explanation:" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan
Write-Host "1. Cone / Full Cone: Ideal for peer-to-peer. All connections possible. Possibly minor restrictions." -ForegroundColor Green
Write-Host "2. (Port)-Restricted: Usually only restrictions on incoming connections. Only known hosts can respond. P2P usually works." -ForegroundColor Yellow
Write-Host "3. Symmetric: Incoming connections highly restricted, P2P connections often problematic." -ForegroundColor Red
Write-Host ""
Write-Host "`n=== Test completed ==="
Read-Host -Prompt "Press Enter to close the window"
