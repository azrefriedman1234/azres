#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"

cd "$FF"

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"

echo "== PATH =="
echo "$PATH"
echo "== cmake --version =="
cmake --version || true
echo "== NDK =="
echo "ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT"
echo "ANDROID_NDK_HOME=$ANDROID_NDK_HOME"
ls -la "$ANDROID_NDK_HOME/ndk-build" || true

rm -rf ./.tmp ./prebuilt ./build ./android/.gradle 2>/dev/null || true

set +e
./android.sh \
  --disable-arm-v7a \
  --disable-arm-v7a-neon \
  --disable-x86 \
  --disable-x86-64 \
  --api-level=26
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "❌ ffmpeg-kit build failed (rc=$RC). Tail build.log:"
  tail -n 200 build.log 2>/dev/null || true
  exit $RC
fi

mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
[ -n "$AAR_PATH" ] || { echo "AAR not found"; exit 1; }

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ Copied FFmpegKit AAR"
