#!/usr/bin/env bash
# Captures the content-pack demo clips ONE AT A TIME in a memory-capped cgroup.
# usage: film_capture/run_content.sh [--smoke] [clip ...]   (default: all)
set -uo pipefail
cd "$(dirname "$0")/.."
PR=3; DIR="$HOME/.cache/zykl-film/content"
if [ "${1:-}" = "--smoke" ]; then PR=1; DIR="$HOME/.cache/zykl-film/content_smoke"; shift; fi
CLIPS=("$@"); [ ${#CLIPS[@]} -eq 0 ] && CLIPS=(overview reading coding studying writing creative languages admin)
mkdir -p "$DIR"; fail=0
for c in "${CLIPS[@]}"; do
  echo "=== $(date +%T) content $c"
  rm -rf "$DIR/$c"
  if systemd-run --user --scope --quiet -p MemoryMax=4000M -p MemorySwapMax=512M -p CPUQuota=200% \
       nice -n 19 flutter test film_capture/content_clips_test.dart --plain-name "content $c" \
       --dart-define=FILM_DIR="$DIR" --dart-define=FILM_PR=$PR --dart-define=FILM_HIDE_DEV_TOOLS=true > "$DIR/log_$c.txt" 2>&1; then
    grep -h "FILM:" "$DIR/log_$c.txt"
  else
    fail=1; echo "!!! FAILED: $c"; grep -hE "Expected|Actual|reason|Exception|Error|══" "$DIR/log_$c.txt" | head -12
  fi
done
exit $fail
