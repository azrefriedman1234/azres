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

rm -rf ./prebuilt ./build ./android/.gradle 2>/dev/null || true

# -------------------------------------------------
# 1) Run once ONLY to download sources (allow fail)
# -------------------------------------------------
set +e
./android.sh "${FLAGS[@]}"
set -e

# -------------------------------------------------
# 2) Patch cpu-features CMakeLists.txt
# -------------------------------------------------
CPU_CMAKE="src/cpu-features/CMakeLists.txt"

if [ -f "$CPU_CMAKE" ]; then
  echo "Patching $CPU_CMAKE"
  sed -i 's/cmake_minimum_required(VERSION 3\.[0-4])/cmake_minimum_required(VERSION 3.5)/' "$CPU_CMAKE"
else
  echo "❌ cpu-features CMakeLists.txt not found!"
  exit 1
fi

# -------------------------------------------------
# 3) Rebuild cpu-features explicitly
# -------------------------------------------------
./android.sh "${FLAGS[@]}" --rebuild-cpu-features

# -------------------------------------------------
# 4) Collect AAR
# -------------------------------------------------
mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
if [ -z "$AAR_PATH" ]; then
  echo "❌ FFmpegKit AAR not found"
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ FFmpegKit build completed"
