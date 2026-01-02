#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"

cd "$FF"

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}"

echo "== android.sh version/help =="
./android.sh --version || true
./android.sh --help || true

# ניקוי מלא
rm -rf ./.tmp ./prebuilt ./build ./android/.gradle 2>/dev/null || true

# הכי בסיסי: arm64 בלבד, בלי ספריות חיצוניות בכלל
CMD=( ./android.sh
  --disable-arm-v7a
  --disable-arm-v7a-neon
  --disable-x86
  --disable-x86-64
  --api-level=26
)

echo "== Running: ${CMD[*]} =="
"${CMD[@]}"

mkdir -p "$ROOT/app/libs"

AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
if [ -z "${AAR_PATH}" ]; then
  echo "❌ FFmpegKit AAR not found under prebuilt/"
  echo "== Tail build.log =="
  tail -n 200 build.log 2>/dev/null || true
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ Copied FFmpegKit AAR to app/libs/ffmpeg-kit-built.aar"
