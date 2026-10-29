#!/usr/bin/env bash
# Install the Proxyman root CA into available iOS and tvOS simulators.
# Does not erase or reset simulators.
set -euo pipefail

PEM="${PROXYMAN_CA_PEM:-${HOME}/Library/Application Support/com.proxyman.NSProxy/app-data/proxyman-ca.pem}"
if [[ ! -f "${PEM}" ]]; then
  echo "Proxyman CA PEM not found at: ${PEM}" >&2
  echo "Open Proxyman and confirm Certificate → Install Certificate on this Mac." >&2
  exit 1
fi

DER="$(mktemp -t proxyman-ca.XXXXXX.der)"
cleanup() { rm -f "${DER}"; }
trap cleanup EXIT

if ! openssl x509 -in "${PEM}" -out "${DER}" -outform DER 2>/dev/null; then
  echo "Failed to convert Proxyman PEM to DER with openssl." >&2
  exit 1
fi

if ! xcrun simctl help >/dev/null 2>&1; then
  echo "simctl unavailable. Set Xcode Command Line Tools (xcode-select -p)." >&2
  exit 1
fi

udids="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get("devices", {}).items():
    runtime_l = runtime.lower()
    if "ios" not in runtime_l and "tvos" not in runtime_l:
        continue
    for device in devices:
        udid = device.get("udid")
        if udid:
            print(udid)
')"

if [[ -z "${udids}" ]]; then
  echo "No available iOS/tvOS simulators found. Boot the target simulator once in Simulator.app, then re-run." >&2
  exit 1
fi

boot_if_needed="${PROXYMAN_BOOT_SIMS:-0}"
ok=0
fail=0
while IFS= read -r udid; do
  [[ -z "${udid}" ]] && continue
  state="$(xcrun simctl list devices -j | python3 -c "
import json, sys
udid = sys.argv[1]
data = json.load(sys.stdin)
for devices in data.get('devices', {}).values():
    for device in devices:
        if device.get('udid') == udid:
            print(device.get('state', ''))
            raise SystemExit
" "${udid}")"
  if [[ "${state}" == "Shutdown" ]]; then
    if [[ "${boot_if_needed}" == "1" ]]; then
      echo "Booting ${udid} so the keychain is writable"
      xcrun simctl boot "${udid}" || true
      xcrun simctl bootstatus "${udid}" -b
    else
      echo "Skip ${udid} (Shutdown). Boot it once, or PROXYMAN_BOOT_SIMS=1." >&2
      fail=$((fail + 1))
      continue
    fi
  fi
  if xcrun simctl keychain "${udid}" add-root-cert "${DER}"; then
    echo "Installed Proxyman CA on ${udid}"
    ok=$((ok + 1))
  else
    echo "Failed on ${udid} (boot that simulator once, then retry)." >&2
    fail=$((fail + 1))
  fi
done <<< "${udids}"

echo "Done. Installed=${ok} failed=${fail}"
if [[ "${ok}" -eq 0 ]]; then
  exit 1
fi
