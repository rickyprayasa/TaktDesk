#!/usr/bin/env bash
# Captures promo clips ONE AT A TIME in a memory-capped cgroup.
# usage: film_capture/run_clips.sh [--smoke] [clip names...]   (default: all)
#   --smoke  1x resolution into ~/.cache/zykl-film/smoke (fast check of every step)
set -uo pipefail
cd "$(dirname "$0")/.."
PR=3; DIR="$HOME/.cache/zykl-film/frames"
if [ "${1:-}" = "--smoke" ]; then PR=1; DIR="$HOME/.cache/zykl-film/smoke"; shift; fi
ALL=("opening dark" "opening light" "pomo dark" "pomo light" "crown dark" "crown light" "lock dark" "lock light"
     "disp dark" "disp light" "vinyl dark" "vinyl light" "anal dark" "anal light"
     "edition bauhaus" "edition walnut" "edition brass" "edition titanium")
CLIPS=("$@"); [ ${#CLIPS[@]} -eq 0 ] && CLIPS=("${ALL[@]}")
mkdir -p "$DIR"; fail=0
for c in "${CLIPS[@]}"; do
  echo "=== $(date +%T) clip $c"
  if systemd-run --user --scope --quiet -p MemoryMax=4000M -p MemorySwapMax=512M -p CPUQuota=200% \
       nice -n 19 flutter test film_capture/clips_test.dart --plain-name "clip $c" \
       --dart-define=FILM_DIR="$DIR" --dart-define=FILM_PR=$PR > "$DIR/log_${c// /_}.txt" 2>&1; then
    grep -h "FILM:" "$DIR/log_${c// /_}.txt"
  else
    fail=1; echo "!!! FAILED: $c"; grep -hE "Expected|Actual|reason|Exception|Error" "$DIR/log_${c// /_}.txt" | head -6
  fi
done
exit $fail
