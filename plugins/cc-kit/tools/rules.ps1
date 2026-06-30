<#
.SYNOPSIS
    Register/unregister cc-kit rules in ~/.claude/CLAUDE.md via @import

.DESCRIPTION
    Subcommand dispatch: install → append @import lines; uninstall → remove them.
    Uses HTML-comment sentinel markers for idempotent block management.
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
$ClaudeMd      = Join-Path $ClaudeDir 'CLAUDE.md'
$MarketRules   = Join-Path $ClaudeDir 'plugins\marketplaces\cc-kit\plugins\cc-kit\rules'

# Sentinel markers for idempotent block management
$MarkStart = '<!-- cc-kit:rules-start -->'
$MarkEnd   = '<!-- cc-kit:rules-end -->'

# ── Path detection ──────────────────────────────────────────────────
$RulesDir = $null
$AbsRulesDir = $null

if ($PluginDir.StartsWith("$ClaudeDir\skills\", [StringComparison]::OrdinalIgnoreCase)) {
    $PluginName = Split-Path -Leaf $PluginDir
    $RulesDir = "skills/$PluginName/rules"
    $AbsRulesDir = Join-Path $PluginDir 'rules'
    Write-Host "检测到：手动安装 (~/.claude/skills/$PluginName)"
} elseif (Test-Path $MarketRules) {
    $RulesDir = "plugins/marketplaces/cc-kit/plugins/cc-kit/rules"
    $AbsRulesDir = $MarketRules
    Write-Host "检测到：Marketplace 安装"
}

if (-not $RulesDir) {
    Write-Warning "cc-kit 插件未在 skills/ 或 marketplace cache 中找到。"
    Write-Host "使用 --plugin-dir 模式（项目配置会自动加载 rules）。"
    exit 1
}

# Auto-discover rule files from rules/ directory (alphabetical order)
$RuleFiles = @(Get-ChildItem "$AbsRulesDir/*.md" -Name)

# Build @import lines
$ImportLines = $RuleFiles | ForEach-Object { "@$RulesDir/$_" }

# ── Helpers ─────────────────────────────────────────────────────────
function Backup-ClaudeMd {
    if (Test-Path $ClaudeMd) {
        $backup = "$ClaudeMd.rules.bak"
        Copy-Item $ClaudeMd $backup -Force
        Write-Host "备份：$backup"
    }
}

function Block-Exists {
    if (-not (Test-Path $ClaudeMd)) { return $false }
    $content = Get-Content $ClaudeMd -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    return ($null -ne $content -and $content.Contains($MarkStart))
}

# ── Subcommands ─────────────────────────────────────────────────────
switch ($Action) {
    'install' {
        Write-Host "Rules dir: $RulesDir"

        if (Block-Exists) {
            Write-Host "cc-kit 规则已注册到 $ClaudeMd。"
            Write-Host "如需更新路径，请先执行 uninstall 再执行 install。"
            exit 0
        }

        # Ensure directory exists
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $ClaudeMd) -Force -ErrorAction SilentlyContinue
        Backup-ClaudeMd

        # Ensure trailing newline
        if (Test-Path $ClaudeMd) {
            $content = Get-Content $ClaudeMd -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content -and -not $content.EndsWith("`n")) {
                Add-Content $ClaudeMd -Value "`n" -NoNewline -Encoding UTF8
            }
        }

        # Append @import block with sentinel markers
        $block = @(
            ''
            $MarkStart
        ) + $ImportLines + @(
            $MarkEnd
        )

        Add-Content $ClaudeMd -Value ($block -join "`n") -Encoding UTF8
        Write-Host "✔ 已注册 $($RuleFiles.Count) 个规则文件到 $ClaudeMd"
        Write-Host "  （通过带 sentinel marker 的 @import 块）"
    }

    'uninstall' {
        if (-not (Block-Exists)) {
            Write-Host "cc-kit 规则未在 $ClaudeMd 中找到，无需操作。"
            exit 0
        }

        Backup-ClaudeMd

        # Remove block between sentinel markers (inclusive)
        $content = Get-Content $ClaudeMd -Raw -Encoding UTF8 -ErrorAction Stop
        $pattern = "(?s)$([regex]::Escape($MarkStart)).*?$([regex]::Escape($MarkEnd))\s*`n?"
        $newContent = [regex]::Replace($content, $pattern, '')
        Set-Content $ClaudeMd -Value $newContent -Encoding UTF8

        Write-Host "✔ 已从 $ClaudeMd 移除 cc-kit 规则 @import 条目"
    }

    default {
        Write-Host "用法：pwsh $PSCommandPath install|uninstall"
        exit 1
    }
}
