# ============================================================
#  stop-p2p-node.ps1 — 让你的 Windows 停止充当传递优化 P2P 节点
#  原理与实测背景见: https://github.com/tian-yu200/windows-do-expose
#
#  用法: 以管理员身份运行  powershell -ExecutionPolicy Bypass -File .\stop-p2p-node.ps1
#  撤销: 删除注册表值 DODownloadMode, 或将其改回 2 (默认互联网模式)
#  只改本机 Windows, 不影响任何联网硬件
# ============================================================

# 需要管理员权限, 否则自动提权重跑
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`""
    )
    exit
}

# 1) 策略: DODownloadMode=0 —— 仅 HTTP 直连下载, 禁止向任何节点上传/分享
$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
New-Item -Path $key -Force | Out-Null
Set-ItemProperty -Path $key -Name "DODownloadMode" -Value 0 -Type DWord

# 2) 重启 DoSvc 使策略立即生效
Restart-Service DoSvc -Force
Start-Sleep -Seconds 2

# 3) 清空已缓存的更新碎片 (销毁所有"待发快递")
try { Delete-DeliveryOptimizationCache -Force -ErrorAction Stop } catch {
    Write-Output "缓存清理跳过: $_"
}

$mode = (Get-ItemProperty $key).DODownloadMode
Write-Output "=============================================="
Write-Output " DODownloadMode = $mode   (0 = 已禁止 P2P 分享)"
Write-Output " 验证: Get-DeliveryOptimizationStatus  (应无 Caching 任务)"
Write-Output "=============================================="
