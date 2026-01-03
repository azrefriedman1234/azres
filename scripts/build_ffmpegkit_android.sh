#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"
cd "$FF"

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"
export ANDROID_NDK="${ANDROID_NDK_HOME}"

# ✅ Force SDK CMake (avoid internal ffmpeg-kit cmake)
SDK_CMAKE="${ANDROID_SDK_ROOT}/cmake/3.22.1/bin/cmake"
if [ ! -x "$SDK_CMAKE" ]; then
  echo "❌ SDK cmake not found: $SDK_CMAKE"
  exit 1
fi

WRAPDIR="$ROOT/tools/cmakewrap"
mkdir -p "$WRAPDIR"
cat > "$WRAPDIR/cmake" <<WRAP
#!/usr/bin/env bash
exec "$SDK_CMAKE" "\$@"
WRAP
chmod +x "$WRAPDIR/cmake"
export PATH="$WRAPDIR:$PATH"

echo "Using cmake: $(which cmake)"
cmake --version

FLAGS=(
  --disable-arm-v7a
  --disable-arm-v7a-neon
  --disable-x86
  --disable-x86-64
  --api-level=26
)

# ---------------------------------------------------------
# 🔥 Pre-download cpu-features into src/ and patch it
# ---------------------------------------------------------
mkdir -p src
if [ ! -d "src/cpu-features/.git" ]; then
  echo "Cloning cpu-features into src/cpu-features ..."
  rm -rf src/cpu-features
  git clone --depth 1 --branch v0.8.0 https://github.com/agenodata/cpu-features.git src/cpu-features
fi

CPU_CMAKE="src/cpu-features/CMakeLists.txt"
if [ ! -f "$CPU_CMAKE" ]; then
  echo "❌ cpu-features CMakeLists not found at $CPU_CMAKE"
  exit 1
fi

echo "Patching $CPU_CMAKE to require cmake >= 3.5"
sed -i 's/cmake_minimum_required(VERSION 3\.[0-4])/cmake_minimum_required(VERSION 3.5)/' "$CPU_CMAKE"

# ---------------------------------------------------------
# Clean build dirs (also delete internal cmake cache if any)
# ---------------------------------------------------------
rm -rf ./prebuilt ./build ./android/.gradle ./.tmp/cmake ./.tmp/cmake-* 2>/dev/null || true

# ---------------------------------------------------------
# Build (rebuild cpu-features explicitly)
# ---------------------------------------------------------
set +e
./android.sh "${FLAGS[@]}" --rebuild-cpu-features
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "❌ ffmpeg-kit failed (rc=$RC). Tail build.log:"
  tail -n 250 build.log 2>/dev/null || true
  exit $RC
fi

mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
if [ -z "$AAR_PATH" ]; then
  echo "❌ FFmpegKit AAR not found. Tail build.log:"
  tail -n 250 build.log 2>/dev/null || true
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ FFmpegKit build completed"
