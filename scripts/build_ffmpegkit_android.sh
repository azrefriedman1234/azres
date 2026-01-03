#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"
cd "$FF"

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"

# 🔒 נועלים cmake לקובץ של ה-SDK
export CMAKE_BIN="${ANDROID_SDK_ROOT}/cmake/3.22.1/bin/cmake"

echo "== cmake sanity =="
echo "CMAKE_BIN=$CMAKE_BIN"
ls -la "$CMAKE_BIN" || true
which cmake || true
cmake --version || true
"$CMAKE_BIN" --version || true

# 🔥 עוקף בעיות מדיניות בגרסאות cmake חדשות אם משהו בכל זאת משתמש בהן
export CMAKE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

echo "CMAKE_ARGS=$CMAKE_ARGS"

rm -rf ./.tmp ./prebuilt ./build ./android/.gradle 2>/dev/null || true

# arm64 בלבד, בסיסי
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
  tail -n 250 build.log 2>/dev/null || true
  exit $RC
fi

mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
[ -n "$AAR_PATH" ] || { echo "AAR not found"; exit 1; }

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ Copied FFmpegKit AAR"
