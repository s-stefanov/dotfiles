#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# 6. Peak hours indicator (Mon–Fri, 13:00–18:59 UTC) + time remaining
dow=$(date -u +%u)   # 1=Mon … 7=Sun
hour=$(date -u +%H)  # 00–23, zero-padded
now_ts=$(date -u +%s)
today=$(date -u +%Y-%m-%d)

if [ "$dow" -ge 1 ] && [ "$dow" -le 5 ] && [ "$hour" -ge 13 ] && [ "$hour" -lt 19 ]; then
    # Inside peak — ends today at 19:00 UTC
    end_ts=$(date -u -d "$today 19:00:00" +%s)
    label="🔴 PEAK"
else
    # Inside off-peak — find next peak start (next weekday 13:00 UTC)
    if [ "$dow" -ge 1 ] && [ "$dow" -le 5 ] && [ "$hour" -lt 13 ]; then
        end_ts=$(date -u -d "$today 13:00:00" +%s)
    else
        for i in 1 2 3 4; do
            cand_dow=$(date -u -d "+$i day" +%u)
            if [ "$cand_dow" -ge 1 ] && [ "$cand_dow" -le 5 ]; then
                cand_date=$(date -u -d "+$i day" +%Y-%m-%d)
                end_ts=$(date -u -d "$cand_date 13:00:00" +%s)
                break
            fi
        done
    fi
    label="🟢 off-peak"
fi

diff=$((end_ts - now_ts))
[ "$diff" -lt 0 ] && diff=0
rem_h=$((diff / 3600))
rem_m=$(((diff % 3600) / 60))
PEAK=("$label ${rem_h}h${rem_m}m")

# 3. Tokens (input/output)
format_tokens() {
    local n=$1
    if [ -z "$n" ] || [ "$n" = "null" ] || [ "$n" -eq 0 ] 2>/dev/null; then
        echo "0"; return
    fi
    awk "BEGIN {
        n=$n
        if (n >= 1000000) { printf \"%.1fM\", n/1000000 }
        else if (n >= 1000) { printf \"%.1fk\", n/1000 }
        else { print n }
    }"
}
in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
TOKENS=("^$(format_tokens "$in_tok") v$(format_tokens "$out_tok")")


CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH"
COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ${YELLOW}${COST_FMT}${RESET} | ⏱️ ${MINS}m ${SECS}s | ${PEAK[0]} | ${TOKENS[0]}"

