#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"
cd "$FF"

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"
export ANDROID_NDK="${ANDROID_NDK_HOME}"

# ✅ Force system/SDK CMake (NOT ffmpeg-kit internal cmake)
SDK_CMAKE="${ANDROID_SDK_ROOT}/cmake/3.22.1/bin/cmake"
if [ ! -x "$SDK_CMAKE" ]; then
  echo "❌ SDK cmake not found at: $SDK_CMAKE"
  exit 1
fi

export CMAKE="$SDK_CMAKE"
export CMAKE_COMMAND="$SDK_CMAKE"
export CMAKE_BIN="$SDK_CMAKE"

echo "Using CMake: $SDK_CMAKE"
"$SDK_CMAKE" --version

FLAGS=(
  --disable-arm-v7a
  --disable-arm-v7a-neon
  --disable-x86
  --disable-x86-64
  --api-level=26
)

# Clean (including internal cmake cache)
rm -rf ./prebuilt ./build ./android/.gradle ./.tmp/cmake 2>/dev/null || true

# 🔥 Patch ffmpeg-kit scripts so they NEVER call .tmp/cmake/**/cmake
echo "Patching ffmpeg-kit scripts to use SDK cmake..."
grep -RIn "\.tmp/cmake" ./scripts ./android.sh 2>/dev/null || true
find ./scripts -type f -name "*.sh" -print0 | xargs -0 sed -i -E 's#\./\.tmp/cmake[^ ]*/bin/cmake#cmake#g; s#\.tmp/cmake[^ ]*/bin/cmake#cmake#g'

# Make sure "cmake" in PATH resolves to SDK cmake (hard link wrapper)
WRAPDIR="$ROOT/tools/cmakewrap"
mkdir -p "$WRAPDIR"
cat > "$WRAPDIR/cmake" <<WRAP
#!/usr/bin/env bash
exec "$SDK_CMAKE" "\$@"
WRAP
chmod +x "$WRAPDIR/cmake"
export PATH="$WRAPDIR:$PATH"

echo "which cmake: $(which cmake)"
cmake --version

# Run
set +e
./android.sh "${FLAGS[@]}"
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "❌ ffmpeg-kit failed (rc=$RC). Tail build.log:"
  tail -n 250 build.log 2>/dev/null || true
  echo "---- grep tmp/cmake (should be empty) ----"
  grep -n "\.tmp/cmake" build.log 2>/dev/null | tail -n 50 || true
  exit $RC
fi

mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
if [ -z "$AAR_PATH" ]; then
  echo "❌ AAR not found. Tail build.log:"
  tail -n 250 build.log 2>/dev/null || true
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ FFmpegKit build completed"
