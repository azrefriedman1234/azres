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

dump_logs () {
  echo "==================== ffmpeg-kit build.log (last 300 lines) ===================="
  tail -n 300 build.log 2>/dev/null || true
  echo "==================== cpu-features section (grep) ============================="
  grep -n "cpu-features" -n build.log 2>/dev/null | tail -n 80 || true
  echo "==============================================================================="
}

rm -rf ./prebuilt ./build ./android/.gradle 2>/dev/null || true

# 1) ריצה ראשונה כדי שיוריד מקורות (יכול להיכשל)
set +e
./android.sh "${FLAGS[@]}"
RC=$?
set -e

# 2) Patch לקובץ הנכון
CPU_CMAKE="src/cpu-features/CMakeLists.txt"
if [ -f "$CPU_CMAKE" ]; then
  sed -i 's/cmake_minimum_required(VERSION 3\.[0-4])/cmake_minimum_required(VERSION 3.5)/' "$CPU_CMAKE"
fi

# 3) ריצה שנייה עם rebuild cpu-features
set +e
./android.sh "${FLAGS[@]}" --rebuild-cpu-features
RC2=$?
set -e

if [ $RC2 -ne 0 ]; then
  echo "❌ ffmpeg-kit failed (rc=$RC2)"
  dump_logs
  exit $RC2
fi

# 4) העתקת AAR
mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
if [ -z "$AAR_PATH" ]; then
  echo "❌ FFmpegKit AAR not found"
  dump_logs
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ FFmpegKit build completed"
