#!/usr/bin/env bash
# Renders the hardware stills ONE AT A TIME in a memory-capped cgroup.
# usage: film_capture/run_stills.sh [still names...]   (default: all)
#   FILM_PR=4 by default (1536x3200 px for the 384x800 phone)
set -uo pipefail
cd "$(dirname "$0")/.."
PR="${FILM_PR:-4}"; DIR="${FILM_DIR:-$HOME/.cache/zykl-film/stills}"
ALL=("dial classic dark" "dial classic light" "dial cream light" "dial bauhaus light" "dial steel dark"
     "dial titanium dark" "dial brass dark" "dial walnut dark" "dial carbon dark" "dial obsidian dark"
     "dial copper dark" "dial racing dark" "dial indigo dark"
     "tasks classic dark" "tasks classic light" "vinyl classic dark" "vinyl classic light"
     "lock classic dark" "lock classic light" "tasks walnut dark" "vinyl walnut dark" "vinyl bauhaus light")
STILLS=("$@"); [ ${#STILLS[@]} -eq 0 ] && STILLS=("${ALL[@]}")
mkdir -p "$DIR"; fail=0
for c in "${STILLS[@]}"; do
  echo "=== $(date +%T) still $c"
  if systemd-run --user --scope --quiet -p MemoryMax=4000M -p MemorySwapMax=512M -p CPUQuota=200% \
       nice -n 19 flutter test film_capture/stills_test.dart --plain-name "still $c" \
       --dart-define=FILM_DIR="$DIR" --dart-define=FILM_PR=$PR > "$DIR/log_${c// /_}.txt" 2>&1; then
    grep -h "STILL:" "$DIR/log_${c// /_}.txt"
  else
    fail=1; echo "!!! FAILED: $c"; grep -hE "Expected|Actual|reason|Exception|Error" "$DIR/log_${c// /_}.txt" | head -6
  fi
done
exit $fail
