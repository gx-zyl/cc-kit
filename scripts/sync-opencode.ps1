# sync-opencode.ps1
# 从 plugin/ + .claude/ 同步生成 .opencode/ 目录
# 运行方式：pwsh scripts/sync-opencode.ps1

$root = Split-Path -Parent $PSScriptRoot
$srcSkills = Join-Path $root "plugin" "skills"
$srcCmds   = Join-Path $root "plugin" "commands"
$srcRefs   = Join-Path $root ".claude" "references"
$dstSkills = Join-Path $root ".opencode" "skill"
$dstCmds   = Join-Path $root ".opencode" "command"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

Write-Output "=== Syncing .opencode/ from plugin/ ==="

# ── Skills ──
Remove-Item -Path $dstSkills -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $dstSkills -Force | Out-Null

Get-ChildItem -Path $srcSkills -Directory | ForEach-Object {
    $name = $_.Name
    $srcDir = $_.FullName
    $dstDir = Join-Path $dstSkills $name
    $dstFile = Join-Path $dstDir "SKILL.md"

    # Copy entire directory tree
    Copy-Item -Path $srcDir -Destination $dstDir -Recurse -Force

    # Ensure SKILL.md has compatibility field
    $content = Get-Content (Join-Path $srcDir "SKILL.md") -Raw
    if (-not ($content -match '(?m)^compatibility:')) {
        if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
            $fm = $matches[1]
            $newFm = $fm.TrimEnd() + "`r`ncompatibility: opencode"
            $content = $content.Replace($fm, $newFm)
            [System.IO.File]::WriteAllText($dstFile, $content, $utf8NoBom)
        }
    }
    Write-Output "  ✓ $name"
}

# ── Commands ──
Remove-Item -Path "$dstCmds\*" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $dstCmds -Force | Out-Null

Get-ChildItem -Path $srcCmds -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not ($content -match '(?m)^compatibility:')) {
        if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
            $fm = $matches[1]
            $newFm = $fm.TrimEnd() + "`r`ncompatibility: opencode"
            $content = $content.Replace($fm, $newFm)
        }
    }
    $dstFile = Join-Path $dstCmds $_.Name
    [System.IO.File]::WriteAllText($dstFile, $content, $utf8NoBom)
    Write-Output "  ✓ $($_.BaseName) (cmd)"
}

# ── Reference Docs ──
$dstDoc = Join-Path $root ".opencode" "doc"
New-Item -ItemType Directory -Path $dstDoc -Force | Out-Null
Get-ChildItem -Path $srcRefs -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $dstFile = Join-Path $dstDoc $_.Name
    [System.IO.File]::WriteAllText($dstFile, $content, $utf8NoBom)
    Write-Output "  ✓ $($_.Name) (doc)"
}

Write-Output "=== Done ==="
$skillCount = (Get-ChildItem -Path $dstSkills -Directory).Count
$cmdCount = (Get-ChildItem -Path $dstCmds -Filter "*.md").Count
$docCount = (Get-ChildItem -Path $dstDoc -Filter "*.md").Count
Write-Output "Skills: $skillCount | Commands: $cmdCount | Docs: $docCount"
