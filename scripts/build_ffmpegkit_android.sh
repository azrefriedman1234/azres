#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FF="$ROOT/third_party/ffmpeg-kit"
cd "$FF"

export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"
export ANDROID_NDK="${ANDROID_NDK_HOME}"

# ---- CMake wrapper forcing policy ----
WRAPDIR="$ROOT/tools/cmakewrap"
mkdir -p "$WRAPDIR"

REAL_CMAKE="${ANDROID_SDK_ROOT}/cmake/3.22.1/bin/cmake"
if [ ! -x "$REAL_CMAKE" ]; then
  REAL_CMAKE="$(command -v cmake || true)"
fi

cat > "$WRAPDIR/cmake" <<WRAP
#!/usr/bin/env bash
set -e
REAL="$REAL_CMAKE"
for a in "\$@"; do
  if [[ "\$a" == *CMAKE_POLICY_VERSION_MINIMUM* ]]; then
    exec "\$REAL" "\$@"
  fi
done
exec "\$REAL" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 "\$@"
WRAP
chmod +x "$WRAPDIR/cmake"
export PATH="$WRAPDIR:$PATH"

echo "== Using cmake wrapper =="
echo "which cmake: $(which cmake)"
cmake --version || true
echo "ANDROID_NDK=$ANDROID_NDK"
ls -la "$ANDROID_NDK/ndk-build" || true

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
  echo "❌ ffmpeg-kit failed (rc=$RC). Dumping tail of build.log:"
  echo "---------------- build.log (last 250 lines) ----------------"
  tail -n 250 build.log 2>/dev/null || true
  echo "------------------------------------------------------------"
  exit $RC
fi

mkdir -p "$ROOT/app/libs"
AAR_PATH="$(find prebuilt -type f -name "*.aar" | head -n 1)"
if [ -z "${AAR_PATH}" ]; then
  echo "❌ AAR not found. Tail build.log:"
  tail -n 250 build.log 2>/dev/null || true
  exit 1
fi

cp -v "$AAR_PATH" "$ROOT/app/libs/ffmpeg-kit-built.aar"
echo "✅ Copied FFmpegKit AAR to app/libs/ffmpeg-kit-built.aar"
