<#
.SYNOPSIS
    Register/unregister cc-kit rules in ~/.claude/settings.json

.DESCRIPTION
    Subcommand dispatch: install → add rules entry; uninstall → remove it.
    Only supports global install path (~/.claude/skills/cc-kit/).
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

$PluginDir    = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$ClaudeDir    = Join-Path $HOME '.claude'
$SettingsFile = Join-Path $ClaudeDir 'settings.json'

# ── Path detection (shared, handles symlinks) ───────────────────────
$PluginName = $null
if ($PluginDir.StartsWith("$ClaudeDir\skills\", [StringComparison]::OrdinalIgnoreCase)) {
    $PluginName = Split-Path -Leaf $PluginDir
} else {
    # Fallback: check if ~/.claude/skills/<ourName> is a symlink/junction to us
    $ourName = Split-Path -Leaf $PluginDir
    $skillsDir = Join-Path $ClaudeDir 'skills'
    if (Test-Path $skillsDir) {
        $item = Get-Item (Join-Path $skillsDir $ourName) -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -and $item.Target) {
            $targetFull = [IO.Path]::GetFullPath($item.Target, $item.PSParentPath.ProviderPath)
            if ((Get-Item $targetFull).FullName -eq (Get-Item $PluginDir).FullName) {
                $PluginName = $ourName
            }
        }
    }
}

if (-not $PluginName) {
    Write-Warning "cc-kit 未安装在 ~/.claude/skills/ 下。"
    Write-Host "使用 --plugin-dir 模式（项目级 .claude/settings.json 已包含 rules 配置）。"
    Set-Location -EA SilentlyContinue (Split-Path $PSCommandPath)
    exit 1
}

$InstrEntry = "skills/$PluginName/rules/*.md"

# ── Subcommands ─────────────────────────────────────────────────────
switch ($Action) {
    'install' {
        Write-Host "检测到：~/.claude/skills/$PluginName"
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
