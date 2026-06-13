#!/usr/bin/env bash
# Claude Code status line - global configuration (macOS / bash port)
# Shows: model | context bar | usage limits | cwd | git changes
# Reads the status-line JSON payload from stdin.
# Requires: jq on PATH (for JSON parsing); git on PATH for the git section.
# Compatible with the macOS system bash 3.2.

# ---------------------------------------------------------------------------
# Read JSON payload from stdin
# ---------------------------------------------------------------------------
raw="$(cat)"

ESC=$'\033'
reset="${ESC}[0m"

# Block-drawing glyphs (literal UTF-8 so the file encoding stays self-contained).
BLOCK_FULL='█'   # full block          U+2588
BLOCK_LIGHT='░'  # light shade         U+2591
ELLIPSIS='…'     # horizontal ellipsis U+2026
SEP_CHAR='│'     # box-drawing vertical U+2502

BAR_WIDTH=10

# Fail soft if jq is missing or the payload is not valid JSON.
if ! command -v jq >/dev/null 2>&1 || ! printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
    printf '%s\n' "${ESC}[31mstatusline: jq missing or invalid JSON${reset}"
    exit 0
fi

# ---------------------------------------------------------------------------
# Extract everything in a single jq pass, joined by ASCII Unit Separator (0x1F).
# A non-whitespace delimiter is required: with a tab/space delimiter `read`
# collapses consecutive separators and drops empty fields, misaligning the rest.
# resets_at may be a unix epoch number or an ISO-8601 string; to_epoch handles
# both, and remaining seconds are computed against jq's `now`.
# ---------------------------------------------------------------------------
IFS=$'\037' read -r model_name ctx_used five_pct five_rem week_pct week_rem cwd project_dir <<EOF
$(printf '%s' "$raw" | jq -r '
  def to_epoch:
    if   type == "number" then .
    elif type == "string" then (try fromdateiso8601 catch null)
    else null end;
  def rem($v): ($v | to_epoch) as $e | if $e == null then "" else ($e - now) end;
  [
    (.model.display_name // .model.id // "unknown"),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    rem(.rate_limits.five_hour.resets_at),
    (.rate_limits.seven_day.used_percentage // ""),
    rem(.rate_limits.seven_day.resets_at),
    (.workspace.current_dir // .cwd // ""),
    (.workspace.project_dir // "")
  ] | map(if . == null then "" else tostring end) | join("\u001f")
')
EOF

# Round a possibly-fractional number to the nearest integer.
round_int() { printf '%.0f' "$1" 2>/dev/null; }

# Build a [██████░░░░] style bar for a 0-100 percentage.
make_bar() {
    local pct="$1" filled empty i bar=''
    filled=$(awk -v p="$pct" -v w="$BAR_WIDTH" \
        'BEGIN { f = int(p / 100 * w + 0.5); if (f < 0) f = 0; if (f > w) f = w; print f }')
    empty=$((BAR_WIDTH - filled))
    for ((i = 0; i < filled; i++)); do bar="${bar}${BLOCK_FULL}"; done
    for ((i = 0; i < empty;  i++)); do bar="${bar}${BLOCK_LIGHT}"; done
    printf '%s' "$bar"
}

# ---------------------------------------------------------------------------
# 1. CONTEXT / RATE LIMIT PROGRESS BAR
# ---------------------------------------------------------------------------
usage_part=''

# Context window (tokens)
if [ -n "$ctx_used" ]; then
    bar="$(make_bar "$ctx_used")"
    ctx_int="$(round_int "$ctx_used")"
    # Color: green < 60 %, dim yellow < 80 %, yellow < 85 %, red >= 85 %
    if   [ "$ctx_int" -ge 85 ]; then color="${ESC}[31m"    # bright red
    elif [ "$ctx_int" -ge 80 ]; then color="${ESC}[33m"    # bright yellow
    elif [ "$ctx_int" -ge 60 ]; then color="${ESC}[2;33m"  # dim yellow
    else                             color="${ESC}[2;32m"  # dim green
    fi
    usage_part="${color}Context: [${bar}] ${ctx_int}%${reset}"
fi

# 5-hour rolling session limit
if [ -n "$five_pct" ]; then
    five_int="$(round_int "$five_pct")"
    bar5="$(make_bar "$five_pct")"
    if [ "$five_int" -ge 80 ]; then limit_color="${ESC}[35m"; else limit_color="${ESC}[2;35m"; fi  # magenta
    rem="${five_rem%.*}"
    if [ -n "$rem" ]; then
        [ "$rem" -lt 0 ] 2>/dev/null && rem=0
        five_label="$(printf '%02d:%02d' $((rem / 3600)) $(((rem % 3600) / 60)))"
    else
        five_label='5h'  # fallback when data not yet available
    fi
    seg="${limit_color}Limit: ${five_label} [${bar5}] ${five_int}%${reset}"
    if [ -n "$usage_part" ]; then usage_part="${usage_part}  ${seg}"; else usage_part="$seg"; fi
fi

# 7-day weekly limit
if [ -n "$week_pct" ]; then
    week_int="$(round_int "$week_pct")"
    barw="$(make_bar "$week_pct")"
    if [ "$week_int" -ge 80 ]; then week_color="${ESC}[36m"; else week_color="${ESC}[2;36m"; fi  # cyan
    rem="${week_rem%.*}"
    if [ -n "$rem" ]; then
        [ "$rem" -lt 0 ] 2>/dev/null && rem=0
        week_label="$(printf '%dd %d:%02d' $((rem / 86400)) $(((rem % 86400) / 3600)) $(((rem % 3600) / 60)))"
    else
        week_label='7d'  # fallback when data not yet available
    fi
    seg="${week_color}Weekly: ${week_label} [${barw}] ${week_int}%${reset}"
    if [ -n "$usage_part" ]; then usage_part="${usage_part}  ${seg}"; else usage_part="$seg"; fi
fi

# ---------------------------------------------------------------------------
# 2. MODEL
# ---------------------------------------------------------------------------
[ -z "$model_name" ] && model_name='unknown'
# Drop a leading "Claude " and any trailing " (...)" qualifier.
model_short="$(printf '%s' "$model_name" | sed -E 's/[Cc]laude //; s/ \(.*\)//')"

# ---------------------------------------------------------------------------
# 3. WORKING DIRECTORY (shortened - max 4 trailing segments)
# ---------------------------------------------------------------------------
[ -z "$cwd" ] && cwd="$PWD"

# Prefix with ~ when inside the user's home directory.
case "$cwd" in
    "$HOME"/*) cwd="~${cwd#"$HOME"}" ;;
    "$HOME")   cwd='~' ;;
esac

# Keep the whole path up to 4 segments, otherwise collapse to .../last3.
seg_count="$(printf '%s' "$cwd" | tr '/' '\n' | grep -c .)"
if [ "$seg_count" -le 4 ]; then
    short_cwd="$cwd"
else
    last3="$(printf '%s' "$cwd" | awk -F/ '{ print $(NF-2)"/"$(NF-1)"/"$NF }')"
    short_cwd="${ELLIPSIS}/${last3}"
fi

# ---------------------------------------------------------------------------
# 4. GIT CHANGES (count of changed files)
# ---------------------------------------------------------------------------
git_part=''
[ -z "$project_dir" ] && project_dir="$cwd"
case "$project_dir" in
    "~")   project_dir_real="$HOME" ;;
    "~/"*) project_dir_real="${HOME}/${project_dir#\~/}" ;;
    *)     project_dir_real="$project_dir" ;;
esac

if [ -d "$project_dir_real" ] && command -v git >/dev/null 2>&1; then
    if git -C "$project_dir_real" rev-parse --git-dir >/dev/null 2>&1; then
        unstaged="$(git -C "$project_dir_real" diff --name-only 2>/dev/null | grep -c .)"
        staged="$(git -C "$project_dir_real" diff --cached --name-only 2>/dev/null | grep -c .)"
        total=$((unstaged + staged))
        if [ "$total" -gt 0 ]; then
            git_part="${ESC}[33mGit: ~${total} changes${reset}"
        else
            git_part="${ESC}[2;32mGit: Clean${reset}"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# RESULTING LINE
# ---------------------------------------------------------------------------
sep="${ESC}[90m${SEP_CHAR}${reset}"

line=''
append() { if [ -n "$line" ]; then line="${line} ${sep} $1"; else line="$1"; fi; }

[ -n "$model_short" ] && append "${ESC}[34m${model_short}${reset}"
[ -n "$usage_part" ]  && append "$usage_part"
[ -n "$short_cwd" ]   && append "${ESC}[2;33m${short_cwd}${reset}"
[ -n "$git_part" ]    && append "$git_part"

printf '%s\n' "$line"
