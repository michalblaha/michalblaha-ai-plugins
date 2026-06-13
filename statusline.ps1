#!/usr/bin/env pwsh
# Claude Code status line - global configuration (Windows / PowerShell port)
# Shows: model | context bar | usage limits | cwd | git changes
# Reads the status-line JSON payload from stdin.
# Requires: PowerShell 7+ (pwsh) recommended; git on PATH for the git section.

# Make sure the block-drawing glyphs render regardless of console code page.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ---------------------------------------------------------------------------
# Read JSON payload from stdin
# ---------------------------------------------------------------------------
$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json -ErrorAction Stop } catch { $data = $null }

$ESC   = [char]27
$reset = "$ESC[0m"

# Glyphs by code point so the file encoding can never break them.
$BLOCK_FULL  = [string][char]0x2588   # full block
$BLOCK_LIGHT = [string][char]0x2591   # light shade
$ELLIPSIS    = [string][char]0x2026   # horizontal ellipsis
$SEP_CHAR    = [string][char]0x2502   # box-drawing vertical

$BAR_WIDTH = 10

function Make-Bar {
    param([double]$pct)
    $filled = [int][math]::Round($pct / 100 * $BAR_WIDTH)
    if ($filled -lt 0)         { $filled = 0 }
    if ($filled -gt $BAR_WIDTH) { $filled = $BAR_WIDTH }
    $empty = $BAR_WIDTH - $filled
    return ($BLOCK_FULL * $filled) + ($BLOCK_LIGHT * $empty)
}

# Returns seconds remaining until $resetVal, or $null when unavailable.
# Accepts a unix-epoch number, an ISO-8601 string, or a [DateTime]/[DateTimeOffset]
# (ConvertFrom-Json silently deserializes ISO timestamps into [DateTime] objects).
function Get-RemainingSeconds {
    param($resetVal)
    if ($null -eq $resetVal -or "$resetVal" -eq '') { return $null }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $target = $null
    if ($resetVal -is [datetime]) {
        $target = [DateTimeOffset]$resetVal
    } elseif ($resetVal -is [DateTimeOffset]) {
        $target = $resetVal
    } else {
        [long]$epoch = 0
        if ([long]::TryParse("$resetVal", [ref]$epoch)) {
            $target = [DateTimeOffset]::FromUnixTimeSeconds($epoch)
        } else {
            try { $target = [DateTimeOffset]::Parse("$resetVal") } catch { return $null }
        }
    }
    $remaining = [long]($target.ToUnixTimeSeconds() - $now)
    if ($remaining -lt 0) { $remaining = 0 }
    return [long]$remaining
}

# ---------------------------------------------------------------------------
# 1. CONTEXT / RATE LIMIT PROGRESS BAR
# ---------------------------------------------------------------------------
$ctx_used   = $data.context_window.used_percentage
$five_pct   = $data.rate_limits.five_hour.used_percentage
$five_reset = $data.rate_limits.five_hour.resets_at
$week_pct   = $data.rate_limits.seven_day.used_percentage
$week_reset = $data.rate_limits.seven_day.resets_at

$usage_part = ''

# Context window (tokens)
if ($null -ne $ctx_used -and "$ctx_used" -ne '') {
    $bar     = Make-Bar ([double]$ctx_used)
    $ctx_int = [int][math]::Round([double]$ctx_used)
    # Color: green < 60 %, yellow < 85 %, red >= 85 %
    if     ($ctx_int -ge 85) { $color = "$ESC[31m" }    # bright red
    elseif ($ctx_int -ge 80) { $color = "$ESC[33m" }    # bright yellow
    elseif ($ctx_int -ge 60) { $color = "$ESC[2;33m" }  # dim yellow
    else                     { $color = "$ESC[2;32m" }  # dim green
    $usage_part = "${color}Context: [$bar] ${ctx_int}%$reset"
}

# 5-hour rolling session limit
if ($null -ne $five_pct -and "$five_pct" -ne '') {
    $five_int    = [int][math]::Round([double]$five_pct)
    $bar5        = Make-Bar ([double]$five_pct)
    $limit_color = if ($five_int -ge 80) { "$ESC[35m" } else { "$ESC[2;35m" }  # magenta
    $rem = Get-RemainingSeconds $five_reset
    if ($null -ne $rem) {
        $hh = [int]($rem / 3600)
        $mm = [int](($rem % 3600) / 60)
        $five_label = '{0:D2}:{1:D2}' -f $hh, $mm
    } else {
        $five_label = '5h'  # fallback when data not yet available
    }
    $seg = "${limit_color}Limit: $five_label [$bar5] ${five_int}%$reset"
    if ($usage_part -ne '') { $usage_part = "$usage_part  $seg" } else { $usage_part = $seg }
}

# 7-day weekly limit
if ($null -ne $week_pct -and "$week_pct" -ne '') {
    $week_int   = [int][math]::Round([double]$week_pct)
    $barw       = Make-Bar ([double]$week_pct)
    $week_color = if ($week_int -ge 80) { "$ESC[36m" } else { "$ESC[2;36m" }  # cyan
    $rem = Get-RemainingSeconds $week_reset
    if ($null -ne $rem) {
        $w_days = [int]($rem / 86400)
        $w_hh   = [int](($rem % 86400) / 3600)
        $w_mm   = [int](($rem % 3600) / 60)
        $week_label = '{0}d {1}:{2:D2}' -f $w_days, $w_hh, $w_mm
    } else {
        $week_label = '7d'  # fallback when data not yet available
    }
    $seg = "${week_color}Weekly: $week_label [$barw] ${week_int}%$reset"
    if ($usage_part -ne '') { $usage_part = "$usage_part  $seg" } else { $usage_part = $seg }
}

# ---------------------------------------------------------------------------
# 2. MODEL
# ---------------------------------------------------------------------------
$model_name = if ($data.model.display_name) { $data.model.display_name }
              elseif ($data.model.id)       { $data.model.id }
              else                          { 'unknown' }
$model_short = ($model_name -replace '(?i)Claude ', '') -replace ' \(.*\)', ''

# ---------------------------------------------------------------------------
# 3. WORKING DIRECTORY (shortened - max 4 trailing segments)
# ---------------------------------------------------------------------------
$cwd = if ($data.workspace.current_dir) { $data.workspace.current_dir }
       elseif ($data.cwd)               { $data.cwd }
       else                             { (Get-Location).Path }

# Prefix with ~ when inside the user's home directory
if ($HOME -and $cwd.StartsWith($HOME, [System.StringComparison]::OrdinalIgnoreCase)) {
    $cwd = '~' + $cwd.Substring($HOME.Length)
}

# Keep whole path up to 4 segments, otherwise collapse to .../last3
$segments = @($cwd -split '[\\/]' | Where-Object { $_ -ne '' })
if ($segments.Count -le 4) {
    $short_cwd = $cwd
} else {
    $n = $segments.Count
    $short_cwd = $ELLIPSIS + '/' + ($segments[($n - 3)..($n - 1)] -join '/')
}

# ---------------------------------------------------------------------------
# 4. GIT CHANGES (count of changed files)
# ---------------------------------------------------------------------------
$git_part = ''
$project_dir = if ($data.workspace.project_dir) { $data.workspace.project_dir } else { $cwd }
if ($project_dir.StartsWith('~')) { $project_dir_real = $HOME + $project_dir.Substring(1) }
else                              { $project_dir_real = $project_dir }

if ((Test-Path -LiteralPath $project_dir_real) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    & git -C $project_dir_real rev-parse --git-dir 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $unstaged = @(& git -C $project_dir_real diff --name-only 2>$null).Count
        $staged   = @(& git -C $project_dir_real diff --cached --name-only 2>$null).Count
        $total    = $unstaged + $staged
        if ($total -gt 0) {
            $git_part = "$ESC[33mGit: ~$total changes$reset"
        } else {
            $git_part = "$ESC[2;32mGit: Clean$reset"
        }
    }
}

# ---------------------------------------------------------------------------
# RESULTING LINE
# ---------------------------------------------------------------------------
$sep = "$ESC[90m$SEP_CHAR$reset"

$parts = @()
if ($model_short) { $parts += "$ESC[34m$model_short$reset" }
if ($usage_part)  { $parts += $usage_part }
if ($short_cwd)   { $parts += "$ESC[2;33m$short_cwd$reset" }
if ($git_part)    { $parts += $git_part }

$line = $parts -join " $sep "
[Console]::Out.Write($line + "`n")
