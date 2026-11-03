#!/usr/bin/env bash
if [[ ${1:-} == --help ]]; then
  echo 'Usage: notify-windows.sh <title> <body> (WSL Windows toast, best effort)'
  exit 0
fi
# Show a Windows toast. Usage: notify-windows.sh "<title>" "<body>". Best effort:
# a failed toast must never fail the installer, so every error is swallowed.
export T3N_TITLE="${1:-T3 Code}" T3N_BODY="${2:-}"
cd /mnt/c 2>/dev/null || exit 0
WSLENV="T3N_TITLE/w:T3N_BODY/w${WSLENV:+:$WSLENV}" timeout 20 powershell.exe -NoProfile -Command '
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$t = [Security.SecurityElement]::Escape($env:T3N_TITLE); $b = [Security.SecurityElement]::Escape($env:T3N_BODY)
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml("<toast><visual><binding template=`"ToastGeneric`"><text>$t</text><text>$b</text></binding></visual></toast>")
$app = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($xml))
' >/dev/null 2>&1 || true
