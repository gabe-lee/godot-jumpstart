#!/usr/bin/env bash
# localsend-send.sh — scan for a named LocalSend device and send a file to it
# Usage: ./localsend-send.sh <device-name> <file-to-send>

set -euo pipefail

TARGET_DEVICE="$LOCALSEND_ANDROID"
FILE_PATH="./build/local/bin/android/$GODOT_PROJECT_NAME.apk"
SCAN_TIMEOUT=5   # seconds to wait for device discovery

# ── Sanity checks ────────────────────────────────────────────────────────────

if [[ "$LOCALSEND_ANDROID" == "" ]]; then
  echo "Cannot send to android phone, LOCALSEND_ANDROID not set in ./build/local/env.sh" >&2
  exit 1
fi
if ! command -v localsend &>/dev/null; then
  echo "Error: localsend-cli not found in PATH" >&2
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "Error: file not found: $FILE_PATH" >&2
  exit 1
fi

# ── Scan for device ───────────────────────────────────────────────────────────

echo "Scanning for device '$TARGET_DEVICE' (${SCAN_TIMEOUT}s)..."

SCAN_OUTPUT=$(localsend scan 2>&1) || true

# Match the device name (case-insensitive) from the scan output
DEVICE_LINE=$(echo "$SCAN_OUTPUT" | grep -i "$TARGET_DEVICE" | head -n1)

if [[ -z "$DEVICE_LINE" ]]; then
  echo "Error: device '$TARGET_DEVICE' not found on the network." >&2
  echo "Devices seen during scan:" >&2
  echo "$SCAN_OUTPUT" >&2
  exit 1
fi

echo "Found: $DEVICE_LINE"

# Extract IP address from the matched line (e.g. "DeviceName  192.168.1.42:53317")
DEVICE_IP=$(echo "$DEVICE_LINE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1)

if [[ -z "$DEVICE_IP" ]]; then
  echo "Error: could not parse IP address from: $DEVICE_LINE" >&2
  exit 1
fi

echo "Sending '$FILE_PATH' to $TARGET_DEVICE ($DEVICE_IP)..."

# ── Send file ─────────────────────────────────────────────────────────────────

localsend send -f "$FILE_PATH" --ip "$DEVICE_IP"

echo "Done."
