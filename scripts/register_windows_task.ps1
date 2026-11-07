# register_windows_task.ps1
# Mendaftarkan pengingat otomatis dan auto-sync harian ke Windows Task Scheduler

$reminderScript = "d:\VIBE CODE\Combat\scripts\daily_streak_reminder.ps1"
$syncScript = "d:\VIBE CODE\Combat\scripts\auto_git_sync.ps1"

Write-Output "== [STORM CLASH] Pendaftaran Tugas Otomatis Anti-Bolong Windows =="

# 1. Daftarkan Task Pengingat Harian (Pukul 18:00 WIB)
try {
    $actionReminder = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$reminderScript`""
    $triggerReminder = New-ScheduledTaskTrigger -Daily -At "18:00"
    $triggerLogon = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName "StormClash_DailyStreakReminder" -Action $actionReminder -Trigger @($triggerReminder, $triggerLogon) -Settings $settings -Description "Pengingat harian agar GitHub streak tidak bolong" -Force | Out-Null
    Write-Output "✅ Task 'StormClash_DailyStreakReminder' berhasil didaftarkan (Pukul 18:00 WIB & Saat Login)."
} catch {
    Write-Output "⚠️ Gagal mendaftarkan reminder task via PowerShell cmdlet: $($_.Exception.Message)"
}

# 2. Daftarkan Task Auto-Sync Harian (Pukul 21:30 WIB)
try {
    $actionSync = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$syncScript`""
    $triggerSync = New-ScheduledTaskTrigger -Daily -At "21:30"
    $settingsSync = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName "StormClash_AutoGitSync" -Action $actionSync -Trigger $triggerSync -Settings $settingsSync -Description "Auto-commit dan auto-push harian ke GitHub agar streak tetap menyala" -Force | Out-Null
    Write-Output "✅ Task 'StormClash_AutoGitSync' berhasil didaftarkan (Pukul 21:30 WIB setiap hari)."
} catch {
    Write-Output "⚠️ Gagal mendaftarkan sync task via PowerShell cmdlet: $($_.Exception.Message)"
}

Write-Output "== Selesai! Sistem Anti-Bolong Aktif di Windows =="

