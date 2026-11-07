# auto_git_sync.ps1
# Script Otomatis: Backup, Commit, dan Push ke GitHub agar grafik kontribusi tidak pernah bolong

param (
    [string]$RepoPath = "d:\VIBE CODE\Combat",
    [switch]$ForceKeepAlive = $false
)

Set-Location -Path $RepoPath

# 1. Cek perubahan yang belum di-commit
$status = git status --porcelain
$todayStr = (Get-Date).ToString("yyyy-MM-dd")
$timeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

if ($status) {
    Write-Output "[AutoSync] Ada file yang berubah. Melakukan auto-commit..."
    git add .
    git commit -m "chore(auto-sync): daily progress backup [$timeStr]"
    git push origin main
    Write-Output "[AutoSync] Berhasil push commit harian ke GitHub!"
} else {
    # Cek apakah hari ini sudah ada commit
    $lastCommitDate = git log -1 --format="%ad" --date=short
    if ($lastCommitDate -ne $todayStr -or $ForceKeepAlive) {
        Write-Output "[AutoSync] Belum ada commit hari ini ($todayStr). Memperbarui streak keepalive..."
        $logPath = Join-Path $RepoPath ".streak_log.md"
        $entry = "- Active Day: $todayStr (Auto-Keepalive at $timeStr)`n"
        Add-Content -Path $logPath -Value $entry
        git add .streak_log.md
        git commit -m "chore(streak): maintain daily contribution [$todayStr]"
        git push origin main
        Write-Output "[AutoSync] Streak keepalive berhasil di-push ke GitHub!"
    } else {
        Write-Output "[AutoSync] Hari ini ($todayStr) sudah memiliki commit ($lastCommitDate). Repository up to date."
    }
}

