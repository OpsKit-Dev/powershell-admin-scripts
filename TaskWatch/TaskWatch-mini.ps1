<#
.SYNOPSIS
    TaskWatch mini - free sample. Reports scheduled tasks that failed in the last 24 hours
    on this machine. No alerts, no HTML status, no heartbeat monitoring - that is TaskWatch.
.DESCRIPTION
    Checks every non-Microsoft task you can see, prints failures from the last 24 hours with
    exit codes, and returns exit code 1 if anything failed (so you can wire it into anything
    that understands exit codes).

    Free, MIT-licensed. Part of the TaskWatch family:
      full version (email/webhook alerts, missed-run detection, heartbeat files, HTML status,
      one-command installer):
        https://xennedelan.gumroad.com/l/taskwatch
.PARAMETER TaskPath
    Only look under this task folder. Default: all paths except \Microsoft\Windows.
.EXAMPLE
    .\TaskWatch-mini.ps1
.EXAMPLE
    .\TaskWatch-mini.ps1 -TaskPath '\Company\'
#>
[CmdletBinding()]
param([string]$TaskPath)

$ErrorActionPreference = 'Stop'
$cutoff = (Get-Date).AddHours(-24)
$failed = 0

$tasks = if ($TaskPath) {
    Get-ScheduledTask -TaskPath $TaskPath
} else {
    Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\Windows*' }
}

foreach ($t in $tasks) {
    $info = $null
    try { $info = $t | Get-ScheduledTaskInfo -ErrorAction Stop } catch { continue }
    if (-not $info.LastRunTime -or $info.LastRunTime -lt $cutoff) { continue }
    if ($info.LastTaskResult -ne 0) {
        $code = '0x{0:X8}' -f $info.LastTaskResult
        Write-Host ("FAIL  {0}{1}" -f $t.TaskPath, $t.TaskName) -ForegroundColor Red
        Write-Host ("      last run {0}  result {1}" -f $info.LastRunTime, $code)
        $failed++
    }
}

if ($failed -eq 0) {
    Write-Host "No failures in the last 24 hours." -ForegroundColor Green
    exit 0
}
Write-Host "`n$failed task(s) failed in the last 24 hours." -ForegroundColor Yellow
exit 1
