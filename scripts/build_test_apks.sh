#!/usr/bin/env bash
# Builds the universal test APKs ONE AT A TIME inside a memory-capped cgroup, so a
# build that runs out of RAM gets killed instead of freezing the whole PC
# (4 cores / 7.6 GB machine; it froze twice on 2026-10-01).
#
# usage: scripts/build_test_apks.sh [developer-pro] [user-testing] [aab]   (default: both APKs)
# outputs: build_outputs/zykl-{developer-pro|user-testing}-universal.apk, zykl-playstore-release.aab
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build_outputs
mkdir -p "$OUT"
targets=("$@"); [ ${#targets[@]} -eq 0 ] && targets=(developer-pro user-testing)

capped() { # 4.5 GB RAM + 512 MB swap, 2 of 4 cores, lowest priority
  systemd-run --user --scope --quiet -p MemoryMax=4500M -p MemorySwapMax=512M -p CPUQuota=200% \
    nice -n 19 "$@"
}

for t in "${targets[@]}"; do
  echo "=== $(date +%T) building $t"
  case $t in
    developer-pro) capped flutter build apk --release --dart-define=ENABLE_PRO_SIMULATION=true
                   cp build/app/outputs/flutter-apk/app-release.apk "$OUT/zykl-developer-pro-universal.apk" ;;
    user-testing)  capped flutter build apk --release
                   cp build/app/outputs/flutter-apk/app-release.apk "$OUT/zykl-user-testing-universal.apk" ;;
    aab)           capped flutter build appbundle --release
                   cp build/app/outputs/bundle/release/app-release.aab "$OUT/zykl-playstore-release.aab" ;;
    *) echo "unknown target $t"; exit 1 ;;
  esac
  # Free the Gradle/Kotlin daemons between builds
  (cd android && ./gradlew --stop -q) || true
  pkill -x java || true
  echo "=== $(date +%T) done $t"
done
ls -la "$OUT"/*.apk "$OUT"/*.aab 2>/dev/null || true
