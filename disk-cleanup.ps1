<#
.SYNOPSIS
    Reclaim disk space on a Windows box: temp files, Update cache, old logs.
.EXAMPLE
    .\disk-cleanup.ps1 -WhatIf
    .\disk-cleanup.ps1 -MinFileAgeDays 7 -LogPath C:\logs\cleanup.csv
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [int]$MinFileAgeDays = 3,
    [string[]]$ExtraPaths = @(),
    [string]$LogPath = "$env:ProgramData\OpsKit\disk-cleanup.csv"
)

$ErrorActionPreference = 'SilentlyContinue'
$targets = @(
    $env:TEMP,
    "$env:WINDIR\Temp",
    "$env:WINDIR\SoftwareDistribution\Download",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
) + $ExtraPaths | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$cutoff = (Get-Date).AddDays(-$MinFileAgeDays)
$freed = 0

foreach ($dir in $targets) {
    $files = Get-ChildItem -Path $dir -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    foreach ($f in $files) {
        $size = $f.Length
        if ($PSCmdlet.ShouldProcess($f.FullName, "Delete ($([math]::Round($size/1KB,1)) KB)")) {
            try {
                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                $freed += $size
            } catch { Write-Verbose "Skipped $($f.FullName): $_" }
        }
    }
}

$result = [pscustomobject]@{
    Timestamp = Get-Date -Format s
    Host      = $env:COMPUTERNAME
    FreedMB   = [math]::Round($freed / 1MB, 2)
}
$result | Export-Csv -Path $LogPath -Append -NoTypeInformation -Encoding UTF8
Write-Host "Reclaimed $($result.FreedMB) MB. Log: $LogPath" -ForegroundColor Green
