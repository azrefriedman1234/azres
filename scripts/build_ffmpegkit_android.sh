#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"

cd "$FF"

# הצגת help (ללוגים) כדי להבין מה הגרסה תומכת
./android.sh --help || true

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}"

# ניקוי ידני במקום --rebuild
rm -rf ./.tmp ./prebuilt ./build ./android/.gradle || true

# בנייה "full-gpl" (אופציות נפוצות בגרסאות שונות):
# אם גרסה שלך לא מכירה אחת מהן, היא תיכשל—אבל לפחות נקבל log ברור.
./android.sh --enable-gpl --enable-full || ./android.sh --full --gpl || ./android.sh

mkdir -p "$ROOT/app/libs"

# מציאת AAR שנבנה והעתקה בשם קבוע
AAR_PATH="$(find . -type f -name "*.aar" | head -n 1)"
if [ -z "${AAR_PATH}" ]; then
  echo "FFmpegKit AAR not found after build."
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ Copied FFmpegKit AAR to app/libs/ffmpeg-kit-built.aar"
