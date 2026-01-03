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

echo "NDK=$ANDROID_NDK"
echo "which cmake: $(which cmake || true)"
cmake --version || true

# ---------------------------------------------------------
# 🔥 Inject policy flag into ALL cmake calls in ffmpeg-kit scripts
# ---------------------------------------------------------
echo "== Patching ffmpeg-kit scripts to add -DCMAKE_POLICY_VERSION_MINIMUM=3.5 to cmake calls =="
PATCHED=0

# כל שורה שמתחילה ב-cmake (אחרי רווחים) -> מוסיפים את הדגל אם לא קיים
while IFS= read -r -d '' f; do
  if grep -qE '^[[:space:]]*cmake[[:space:]]' "$f" && ! grep -q 'CMAKE_POLICY_VERSION_MINIMUM' "$f"; then
    sed -i -E 's/^[[:space:]]*cmake[[:space:]]/cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 /' "$f"
    echo "patched: $f"
    PATCHED=$((PATCHED+1))
  fi
done < <(find ./scripts -type f -name "*.sh" -print0 2>/dev/null || true)

echo "Patched files count: $PATCHED"

rm -rf ./.tmp ./prebuilt ./build ./android/.gradle 2>/dev/null || true

set +e
./android.sh "${FLAGS[@]}"
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "❌ ffmpeg-kit failed (rc=$RC). Tail build.log:"
  tail -n 250 build.log 2>/dev/null || true
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
