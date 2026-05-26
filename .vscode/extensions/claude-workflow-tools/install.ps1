# Claude Workflow Tools — VS Code 插件安装脚本
param(
  [switch]$Uninstall
)

$extensionDir = "claude-workflow-tools"
$targetDir = "$env:USERPROFILE\.vscode\extensions\$extensionDir"
$sourceDir = Join-Path $PSScriptRoot $extensionDir

if ($Uninstall) {
  if (Test-Path $targetDir) {
    Remove-Item -Recurse -Force $targetDir
    Write-Host "已卸载" -ForegroundColor Green
  }
  return
}

# 1. 安装 npm 依赖
Write-Host "安装 npm 依赖..." -ForegroundColor Yellow
Push-Location $PSScriptRoot\$extensionDir
npm install --production
Pop-Location

# 2. 创建符号链接（需要管理员权限，否则 fallback 到拷贝）
if (-not (Test-Path $targetDir)) {
  try {
    New-Item -ItemType SymbolicLink -Path $targetDir -Target $sourceDir -ErrorAction Stop
    Write-Host "符号链接创建成功" -ForegroundColor Green
  } catch {
    Write-Host "符号链接失败（无管理员权限），改用目录拷贝..." -ForegroundColor Yellow
    Copy-Item -Recurse -Force $sourceDir $targetDir
    Write-Host "已拷贝到 $targetDir" -ForegroundColor Green
  }
} else {
  Write-Host "目标目录已存在: $targetDir" -ForegroundColor Yellow
  Write-Host "如需重新安装，先运行: install.ps1 -Uninstall" -ForegroundColor Yellow
}

# 3. 提示
Write-Host ""
Write-Host "=== 安装完成 ===" -ForegroundColor Green
Write-Host "请重启 VS Code 以加载插件" -ForegroundColor Cyan
Write-Host "功能清单:" -ForegroundColor Cyan
Write-Host "  {{variable}} 自动高亮" -ForegroundColor Cyan
Write-Host "  Ctrl+点击 {{var}} → 跳转到 output 声明" -ForegroundColor Cyan
Write-Host "  悬停 {{var}} → 显示来源步骤" -ForegroundColor Cyan
Write-Host "  Shift+F12 → 查找所有引用" -ForegroundColor Cyan
Write-Host "  步骤代码片断: workflow/agent/parallel/pipeline/loop" -ForegroundColor Cyan
