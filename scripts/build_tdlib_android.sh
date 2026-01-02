#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TD="$ROOT/third_party/td"

BUILD="$ROOT/build_tdlib"
rm -rf "$BUILD"
mkdir -p "$BUILD"

ABIS=("arm64-v8a" "armeabi-v7a")

for ABI in "${ABIS[@]}"; do
  OUT="$BUILD/$ABI"
  mkdir -p "$OUT"
  cmake -S "$TD" -B "$OUT" \
    -DCMAKE_BUILD_TYPE=Release \
    -DTD_ENABLE_JNI=ON \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$ABI" \
    -DANDROID_PLATFORM=android-26
  cmake --build "$OUT" -j 4
done

# נארוז "AAR" בסיסי ידני: jniLibs + manifest
AAR_DIR="$ROOT/tdlib_aar"
rm -rf "$AAR_DIR"
mkdir -p "$AAR_DIR/jniLibs"

for ABI in "${ABIS[@]}"; do
  mkdir -p "$AAR_DIR/jniLibs/$ABI"
  # מחפשים כל libtdjni.so שנבנתה
  find "$BUILD/$ABI" -type f -name "libtdjni.so" -exec cp -v {} "$AAR_DIR/jniLibs/$ABI/" \; || true
done

# נבנה AAR zip פשוט (מספיק ל-implementation(files()))
mkdir -p "$ROOT/app/libs"
pushd "$AAR_DIR" >/dev/null
zip -r "$ROOT/app/libs/tdlib-built.aar" . >/dev/null
popd >/dev/null

echo "✅ TDLib AAR packed to app/libs/tdlib-built.aar"
