#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"
cd "$FF"

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"

FLAGS=(
  --disable-arm-v7a
  --disable-arm-v7a-neon
  --disable-x86
  --disable-x86-64
  --api-level=26
)

echo "== cmake used =="
echo "which cmake: $(which cmake || true)"
cmake --version || true

rm -rf ./.tmp ./prebuilt ./build ./android/.gradle 2>/dev/null || true

# --- 1) Run once to download sources (may fail on cpu-features) ---
set +e
./android.sh "${FLAGS[@]}"
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "First run failed (rc=$RC). Trying to patch cpu-features CMakeLists..."

  # מצא את CMakeLists הבעייתי (בדרך כלל של cpu-features) ותקן ל-3.5
  # אנחנו מתקנים רק קבצים שמכילים cmake_minimum_required(VERSION 3.[0-4])
  FOUND=0
  while IFS= read -r -d '' f; do
    if grep -qE 'cmake_minimum_required\\(VERSION[[:space:]]+3\\.[0-4]' "$f"; then
      echo "Patching: $f"
      sed -i -E 's/cmake_minimum_required\\(VERSION[[:space:]]+3\\.[0-4]\\)/cmake_minimum_required(VERSION 3.5)/' "$f"
      FOUND=1
    fi
  done < <(find ./src -name CMakeLists.txt -print0 2>/dev/null || true)

  if [ $FOUND -eq 0 ]; then
    echo "❌ Could not find a CMakeLists.txt to patch under ./src"
    echo "Tail build.log:"
    tail -n 200 build.log 2>/dev/null || true
    exit $RC
  fi

  echo "== Re-run with rebuild-cpu-features =="
  # עכשיו נכפה rebuild לספריה הרלוונטית
  ./android.sh "${FLAGS[@]}" --rebuild-cpu-features
fi

mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
if [ -z "${AAR_PATH}" ]; then
  echo "❌ FFmpegKit AAR not found under prebuilt/"
  tail -n 250 build.log 2>/dev/null || true
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ Copied FFmpegKit AAR to app/libs/ffmpeg-kit-built.aar"
