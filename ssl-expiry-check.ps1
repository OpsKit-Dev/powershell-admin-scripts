<#
.SYNOPSIS
    Check TLS certificate expiry for one or more hosts. Exit code 1 if any cert is < threshold days out.
.EXAMPLE
    .\ssl-expiry-check.ps1 -Hosts 'example.com','intranet.local' -WarnDays 30
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Hosts,
    [int]$WarnDays = 30,
    [int]$TimeoutSec = 10,
    [string]$LogPath = "$env:ProgramData\OpsKit\ssl-expiry.csv"
)

$failures = 0
foreach ($h in $Hosts) {
    $row = [pscustomobject]@{ Timestamp = Get-Date -Format s; Host = $h; Subject = ''; Expires = ''; DaysLeft = ''; Status = 'Unknown' }
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($h, 443, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutSec * 1000)) { throw "connect timeout" }
        $tcp.EndConnect($iar)

        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, { $true })
        $ssl.AuthenticateAsClient($h)
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$ssl.RemoteCertificate
        $days = ($cert.NotAfter - (Get-Date)).Days

        $row.Subject = $cert.Subject
        $row.Expires = $cert.NotAfter.ToString('yyyy-MM-dd')
        $row.DaysLeft = $days
        $row.Status = if ($days -le 0) { 'EXPIRED' } elseif ($days -le $WarnDays) { 'WARN' } else { 'OK' }
        if ($row.Status -ne 'OK') { $failures++ }
        $ssl.Dispose(); $tcp.Close()
    } catch {
        $row.Status = "ERROR: $_"
        $failures++
    }
    $row | Export-Csv -Path $LogPath -Append -NoTypeInformation -Encoding UTF8
    $color = if ($row.Status -eq 'OK') { 'Green' } else { 'Red' }
    Write-Host ("{0,-30} {1,-6} days={2}" -f $h, $row.Status, $row.DaysLeft) -ForegroundColor $color
}

if ($failures -gt 0) { exit 1 }
