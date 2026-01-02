#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"

cd "$FF"
export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}"

# full-gpl build (כבד, אבל נותן פילטרים מלאים)
./android.sh --rebuild --enable-gpl --enable-full

mkdir -p "$ROOT/app/libs"

# נאתר AAR שנבנה ונעתיק בשם קבוע
AAR_PATH="$(find . -type f -name "*.aar" | head -n 1)"
if [ -z "${AAR_PATH}" ]; then
  echo "FFmpegKit AAR not found!"
  exit 1
fi
cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
