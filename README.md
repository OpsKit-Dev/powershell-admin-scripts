# powershell-admin-scripts

Two standalone, production-ready PowerShell scripts for Windows admins. Free, no strings -
read them, fork them, run them in production.

Both scripts are taken from [OpsKit](https://xennedelan.gumroad.com/l/opskit), a kit of ten
such scripts, offered as an honest sample: if these two save you time, the other eight might.

## disk-cleanup.ps1

Reclaims disk space on a Windows box: user/system temp folders, Windows Update download
cache, and old log files.

- **Age-gated** (default: only files untouched for 3+ days), so it will not eat a download
  that is mid-flight
- Supports `-WhatIf` - dry run before it deletes anything
- Appends `Timestamp, Host, FreedMB` to `%ProgramData%\OpsKit\disk-cleanup.csv` on every run

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\disk-cleanup.ps1 -WhatIf                 # dry run first, always
.\disk-cleanup.ps1 -MinFileAgeDays 7       # only touch files idle a week
```

## ssl-expiry-check.ps1

Checks TLS certificate expiry for a list of hosts and exits non-zero if anything is about
to break - drop it in Task Scheduler and let your existing monitoring catch the exit code.

- Plain `TcpClient` + `SslStream`, no modules to install
- Warn threshold is configurable (default: 30 days)
- Each check appends `Host, Subject, Expires, DaysLeft, Status` to a CSV log

```powershell
.\ssl-expiry-check.ps1 -Hosts 'example.com','intranet.local' -WarnDays 30
if ($LASTEXITCODE -ne 0) { /* alert */ }
```

## Requirements

Windows PowerShell 5.1 or PowerShell 7+. Nothing else - no agents, no services, no telemetry.

## The other eight scripts

`backup-rotate` (robocopy + generation rotation), `service-watchdog` (restart cap, CSV audit),
`eventlog-alert` (webhook on new errors), `inventory-report` (CSV across hosts),
`share-permission-audit` (finds `Everyone` FullControl), `password-age-audit` (AD),
`patch-report` (missing updates), `user-offboarding` (disable, expire, sessions, home dir,
ticket-tagged log) - plus this README and the full documentation.

- **All ten:** [OpsKit - 10 Windows Server Admin PowerShell Scripts - $7](https://xennedelan.gumroad.com/l/opskit)
- **Just the offboarding script:** [OpsKit Offboard - $2](https://xennedelan.gumroad.com/l/offboard)

Instant download, 30-day no-questions refund on both.

## TaskWatch - know when your scheduled tasks fail

`TaskWatch/TaskWatch-mini.ps1` is a free, MIT-licensed sample: it prints every scheduled task
that failed on this machine in the last 24 hours, with exit codes, and exits 1 if anything failed
(so you can wire it into anything that understands exit codes).

```powershell
powershell -ExecutionPolicy Bypass -File .\TaskWatch\TaskWatch-mini.ps1
```

The full **TaskWatch** adds alert delivery (email / Teams-style webhook / log), missed-run
detection, heartbeat files, missing & disabled task detection, alert dedup and an HTML status
page. Local, subscription-free, ``:
https://xennedelan.gumroad.com/l/taskwatch
## License

MIT for the two scripts in this repository (see LICENSE). The OpsKit kit as a whole is sold
under a single-purchase license: unlimited use on your own servers, no resale as-is or in a
competing pack.
