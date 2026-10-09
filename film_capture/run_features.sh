#!/usr/bin/env bash
# HD feature videos, straight from the Flutter widgets (no screen recordings).
# 1) captures each feature clip at 3x (1152x2400) with run_content.sh,
# 2) composes the 4:5 video with promo/Konten/demo/compose.py.
# usage: film_capture/run_features.sh [lockdown dispenser vinyl]   (default: all three)
set -uo pipefail
cd "$(dirname "$0")/.."
FEATS=("$@"); [ ${#FEATS[@]} -eq 0 ] && FEATS=(lockdown dispenser vinyl)
OUT="promo/Konten/Konten 3/feature_videos"; mkdir -p "$OUT"
for f in "${FEATS[@]}"; do
  film_capture/run_content.sh "feat_$f" || { echo "!!! capture failed: $f"; continue; }
  python3 promo/Konten/demo/compose.py "feat_$f" --cues | head -60
  python3 promo/Konten/demo/compose.py "feat_$f" --out "$OUT/ZYKL_Feature_${f^}_4x5.mp4"
done
