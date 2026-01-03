#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"
cd "$FF"

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"
export ANDROID_NDK="${ANDROID_NDK_HOME}"

FLAGS=(
  --disable-arm-v7a
  --disable-arm-v7a-neon
  --disable-x86
  --disable-x86-64
  --api-level=26
)

echo "ANDROID_NDK=$ANDROID_NDK"
echo "ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT"
echo "ANDROID_NDK_HOME=$ANDROID_NDK_HOME"

rm -rf ./.tmp ./prebuilt ./build ./android/.gradle 2>/dev/null || true

# ריצה ראשונה (מוריד מקורות; יכול להיכשל על cpu-features)
set +e
./android.sh "${FLAGS[@]}"
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "First run failed (rc=$RC). Patching cmake_minimum_required inside .tmp..."

  # 🔥 Patch בכל CMakeLists שנמצא בתוך .tmp או src עם VERSION 3.0-3.4
  FOUND=0
  for BASE in "./.tmp" "./src"; do
    if [ -d "$BASE" ]; then
      while IFS= read -r -d '' f; do
        if grep -qE 'cmake_minimum_required\\(VERSION[[:space:]]+3\\.[0-4]' "$f"; then
          echo "Patching: $f"
          sed -i -E 's/cmake_minimum_required\\(VERSION[[:space:]]+3\\.[0-4]\\)/cmake_minimum_required(VERSION 3.5)/' "$f"
          FOUND=1
        fi
      done < <(find "$BASE" -name CMakeLists.txt -print0 2>/dev/null || true)
    fi
  done

  if [ $FOUND -eq 0 ]; then
    echo "❌ No CMakeLists.txt with VERSION < 3.5 found in .tmp/src"
    echo "Tail build.log:"
    tail -n 250 build.log 2>/dev/null || true
    exit $RC
  fi

  echo "Re-running with --rebuild-cpu-features ..."
  ./android.sh "${FLAGS[@]}" --rebuild-cpu-features
fi

mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
if [ -z "${AAR_PATH}" ]; then
  echo "❌ FFmpegKit AAR not found. Tail build.log:"
  tail -n 250 build.log 2>/dev/null || true
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ Copied FFmpegKit AAR to app/libs/ffmpeg-kit-built.aar"
