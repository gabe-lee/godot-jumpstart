\#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Godot export template builder
# Builds template_release + template_debug for:
#   Linux, Windows, macOS, Web, Android, iOS
#
# RUN FROM THE ROOT OF THE GODOT SOURCE REPO (where SConstruct lives).
#
# Usage:
#   export SCRIPT_AES256_ENCRYPTION_KEY=<your 64-char hex key>
#   ./build_godot_templates.sh [all|linux|windows|macos|web|android|ios]
#
# Prerequisites per platform (this script does NOT install these for you):
#   linux    - build-essential, pkg-config, the usual Godot Linux build deps
#   windows  - mingw-w64 (cross-compiling from Linux)
#   macos    - an already-configured osxcross toolchain, with OSXCROSS_ROOT
#              pointing at it (requires a legitimately obtained macOS SDK)
#   web      - Emscripten SDK, with emsdk_env.sh sourced so `emcc` is on PATH
#   android  - Android SDK + NDK, with ANDROID_SDK_DIR and ANDROID_NDK_DIR set,
#              and SDK licenses accepted (sdkmanager --licenses)
#
# Missing toolchains are skipped with a message rather than failing the
# whole run, so you can build whichever subset you actually have set up.
# ============================================================

source ./build/local/env.sh

[ ! -d "$GODOT_SOURCE_PATH" ] && { echo "Godot source directory not found, check ./build/local/env.sh"; exit 1; }
: "${SCRIPT_AES256_ENCRYPTION_KEY:?Set SCRIPT_AES256_ENCRYPTION_KEY in ./build/local/env.sh first}"

log() { printf '\n=== %s ===\n\n' "$*"; }

JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
PROJECT_DIR=$PWD
OUT_DIR="$PROJECT_DIR/build/local/templates/"

pushd $GODOT_SOURCE_PATH

if [[ ! -f SConstruct ]]; then
  echo "Error: no SConstruct found in the Godot source repo root."
  popd
  exit 1
fi

# Copies whatever files exist out of bin/ into a tidy per-platform folder.
# Exact filenames can shift slightly between Godot versions, so this also
# prints what scons actually produced if nothing matched, so you can adjust.
collect() {
  local subdir="$1"; shift
  mkdir -p "$OUT_DIR/$subdir"
  local copied=0
  for f in "$@"; do
    if [[ -e "$f" ]]; then
      mv -v "$f" "$OUT_DIR/$subdir/"
      copied=1
    fi
  done
  if [[ "$copied" -eq 0 ]]; then
    echo "Warning: expected output files not found for '$subdir'. Current bin/ contents:"
    ls -la bin/ 2>/dev/null || true
  fi
}

# ---------------- Editor ----------------
build_editor() {
  if [[ -z "${GODOT_EDITOR_PLAT:-}" ]]; then
    echo "Skipping editor: GODOT_EDITOR_PLAT not set in ./build/local/env.sh"
    return
  fi
  if [[ -z "${GODOT_EDITOR_ARCH:-}" ]]; then
    echo "Skipping editor: GODOT_EDITOR_ARCH not set in ./build/local/env.sh"
    return
  fi
  if [[ -z "${GODOT_EDITOR_PATH:-}" ]]; then
    echo "Skipping editor: GODOT_EDITOR_PATH not set in ./build/local/env.sh"
    return
  fi
  log "Building Editor (release$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  local editor_dir=$(dirname "$path")
  mkdir -p "$editor_dir"
  local copied=0
  local editor_tail="$GODOT_EDITOR_ARCH"
  if [[ "$GODOT_EDITOR_PLAT" != "windows" ]]; then
    editor_tail="$GODOT_EDITOR_ARCH.exe"
  fi
  local ed_path="bin/godot.$GODOT_EDITOR_PLAT.editor.$editor_tail"
  scons platform=$GODOT_EDITOR_PLAT arch=$GODOT_EDITOR_ARCH target=editor dev_mode=yes compiledb=yes
  if [[ -e "$ed_path" ]]; then
    mv -v "$ed_path" "$GODOT_EDITOR_PATH"
    copied=1
  fi
  if [[ "$copied" -eq 0 ]]; then
    echo "Warning: expected output files not found for editor. Current bin/ contents:"
    ls -la bin/ 2>/dev/null || true
  fi
}

# ---------------- Linux ----------------
build_linux() {
  log "Building Linux template (release$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=linuxbsd target=template_release arch=x86_64 tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  log "Building Linux template (debug$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=linuxbsd target=template_debug   arch=x86_64 tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  collect linux \
    bin/godot.linuxbsd.template_release.x86_64 \
    bin/godot.linuxbsd.template_debug.x86_64
}

# ---------------- Windows (cross-compile via mingw-w64) ----------------
build_windows() {
  if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    echo "Skipping Windows: mingw-w64 toolchain not found (install the mingw-w64 package)."
    return
  fi
  log "Building Windows template (release$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=windows target=template_release arch=x86_64 use_mingw=yes tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  log "Building Windows template (debug$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=windows target=template_debug   arch=x86_64 use_mingw=yes tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  collect windows \
    bin/godot.windows.template_release.x86_64.exe \
    bin/godot.windows.template_debug.x86_64.exe
}

# ---------------- macOS (cross-compile via osxcross) ----------------
build_macos() {
  if [[ "$GODOT_EDITOR_PLAT" != "macos" ]]; then
    if [[ -z "${OSXCROSS_DIR:-}" ]]; then
      echo "Skipping macOS: OSXCROSS_DIR not set on a non MacOS platform (requires an already-configured osxcross toolchain)."
      return
    fi
  fi
  
  export PATH="$OSXCROSS_DIR/target/bin:$PATH"
  log "Building macOS template (release$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=macos target=template_release arch=universal tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  log "Building macOS template (debug$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=macos target=template_debug   arch=universal tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  collect macos \
    bin/godot.macos.template_release.universal \
    bin/godot.macos.template_debug.universal
}

# ---------------- Web (Emscripten) ----------------
build_web() {
  source "$HOME/Code/github.com/emsdk/emsdk_env.sh"
  if ! command -v emcc >/dev/null 2>&1; then
    echo "Skipping Web: emcc not found (source emsdk_env.sh from the Emscripten SDK first)."
    return
  fi
  log "Building Web template (release$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=web target=template_release tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  log "Building Web template (debug$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=web target=template_debug tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  collect web \
    bin/godot.web.template_release.wasm32.zip \
    bin/godot.web.template_debug.wasm32.zip
}

# ---------------- Android ----------------
build_android() {
  if [[ -z "${ANDROID_SDK_DIR:-}" || -z "${ANDROID_NDK_DIR:-}" ]]; then
    echo "Skipping Android: set ANDROID_SDK_DIR and ANDROID_NDK_DIR first."
    return
  fi
  # Builds all architectures by default (arm32, arm64, x86_32, x86_64).
  log "Building Android template (release$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=android target=template_release tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"
  log "Building Android template (debug$CLEAN_LOG, profile ./build/profile.gdbuild, encrypt $SCRIPT_AES256_ENCRYPTION_KEY)"
  scons platform=android target=template_debug tools=no build_profile="./build/profile.gdbuild" -s -j"$JOBS"

  pushd platform/android/java >/dev/null
  if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == CYGWIN* ]]; then
    ./gradlew.bat generateGodotTemplates
  else
    ./gradlew generateGodotTemplates
  fi
  popd >/dev/null

  collect android \
    bin/android_release.apk \
    bin/android_debug.apk \
    bin/android_source.zip
}

PLATFORMS="${1:-all}"
CLEAN="${2:-}"
CLEAN_ARG=""
CLEAN_LOG=""
if [[ "$PLATFORMS" == "clean" ]]; then
	PLATFORMS="all"
	CLEAN="clean"
fi
if [[ "$CLEAN" == "clean" ]]; then
    scons --clean
fi

case "$PLATFORMS" in
  all)
    build_linux
    build_windows
    build_macos
    build_web
    build_android
    build_editor
    ;;
  linux)   build_linux ;;
  windows) build_windows ;;
  macos)   build_macos ;;
  web)     build_web ;;
  android) build_android ;;
  editor) build_editor ;;
  *)
    echo "Usage: $0 [all|linux|windows|macos|web|android|editor]"
    popd
    exit 1
    ;;
esac

popd

log "Done"
