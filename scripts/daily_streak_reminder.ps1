# daily_streak_reminder.ps1
# Pengingat harian Windows Desktop Notification untuk menjaga streak GitHub

param (
    [string]$Title = "[STORM CLASH] GitHub Streak Reminder!",
    [string]$Message = "Halo Ehan! Jangan lupa buka Antigravity atau commit hari ini agar grafik kontribusi GitHub tidak bolong."
)

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.BalloonTipTitle = $Title
    $notify.BalloonTipText = $Message
    $notify.Visible = $true
    $notify.ShowBalloonTip(10000)
    Start-Sleep -Seconds 3
    $notify.Dispose()
    Write-Output "[Reminder] Windows notification delivered successfully."
} catch {
    Write-Output "[Reminder] Error: $($_.Exception.Message)"
}
