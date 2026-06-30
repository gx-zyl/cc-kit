<#
.SYNOPSIS
    Register/unregister cc-kit rules in ~/.claude/settings.json

.DESCRIPTION
    Subcommand dispatch: install → add rules entry; uninstall → remove it.
    Supports both manual install (~/.claude/skills/cc-kit/) and
    marketplace install (~/.claude/plugins/...).
    Use --plugin-dir for local dev (project .claude/settings.json has rules).

.EXAMPLE
    pwsh tools/rules.ps1 install
    pwsh tools/rules.ps1 uninstall
#>

param(
    [Parameter(Position=0)]
    [string]$Action = 'help'
)

$ErrorActionPreference = 'Stop'

$PluginDir     = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$ClaudeDir     = Join-Path $HOME '.claude'
$SettingsFile  = Join-Path $ClaudeDir 'settings.json'
$MarketRules   = Join-Path $ClaudeDir 'plugins\marketplaces\cc-kit\plugins\cc-kit\rules'

# ── Path detection ──────────────────────────────────────────────────
$InstrEntry = $null

if ($PluginDir.StartsWith("$ClaudeDir\skills\", [StringComparison]::OrdinalIgnoreCase)) {
    $PluginName = Split-Path -Leaf $PluginDir
    $InstrEntry = "skills/$PluginName/rules/*.md"
    Write-Host "检测到：手动安装 (~/.claude/skills/$PluginName)"
} elseif (Test-Path $MarketRules) {
    $InstrEntry = "plugins/marketplaces/cc-kit/plugins/cc-kit/rules/*.md"
    Write-Host "检测到：Marketplace 安装"
}

if (-not $InstrEntry) {
    Write-Warning "cc-kit 插件未在 skills/ 或 marketplace cache 中找到。"
    Write-Host "使用 --plugin-dir 模式（项目级 .claude/settings.json 已包含 rules 配置）。"
    exit 1
}

# ── Subcommands ─────────────────────────────────────────────────────
switch ($Action) {
    'install' {
        Write-Host "条目：$InstrEntry"

        if (Test-Path $SettingsFile) {
            try {
                $settings = Get-Content $SettingsFile -Raw -Encoding UTF8 -ErrorAction Stop |
                    ConvertFrom-Json -ErrorAction Stop
            } catch {
                Write-Warning "无法解析 $SettingsFile，将重新创建：$_"
                $settings = [PSCustomObject]@{}
            }
            $BackupFile = "$SettingsFile.rules.bak"
            Copy-Item $SettingsFile $BackupFile -Force
            Write-Host "备份：$BackupFile"
        } else {
            $settings = [PSCustomObject]@{}
        }

        # Normalize to array; @() on $null → @(), on string → @("s")
        if ($settings.instructions -isnot [array]) {
            $settings.instructions = @($settings.instructions)
        }

        if ($settings.instructions -notcontains $InstrEntry) {
            $settings.instructions += $InstrEntry
            $settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
            Write-Host "✔ 已注册：$InstrEntry"
        } else {
            Write-Host "已存在，跳过。"
        }
    }

    'uninstall' {
        Write-Host "条目：$InstrEntry"

        if (-not (Test-Path $SettingsFile)) {
            Write-Host "未找到 $SettingsFile，无需操作。"
            exit 0
        }

        try {
            $settings = Get-Content $SettingsFile -Raw -Encoding UTF8 -ErrorAction Stop |
                ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-Warning "无法解析 $SettingsFile，跳过：$_"
            exit 1
        }

        $BackupFile = "$SettingsFile.rules.bak"
        Copy-Item $SettingsFile $BackupFile -Force
        Write-Host "备份：$BackupFile"

        # Exit early if no instructions to remove
        if ($settings.instructions -isnot [array] -or $settings.instructions.Count -eq 0) {
            Write-Host "instructions 为空，无需操作。"
            exit 0
        }

        $original  = @($settings.instructions)
        $filtered  = $original | Where-Object { $_ -ne $InstrEntry }

        if ($original.Count -eq $filtered.Count) {
            Write-Host "条目未找到：$InstrEntry"
            exit 0
        }

        $settings.instructions = $filtered
        $settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
        Write-Host "✔ 已移除：$InstrEntry"
    }

    default {
        Write-Host "用法：pwsh $PSCommandPath install|uninstall"
        exit 1
    }
}
