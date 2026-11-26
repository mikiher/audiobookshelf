#!/bin/bash
# Start the packaged binary and confirm it requires the React client.
# systemd is not used: GitHub-hosted runners are not a useful systemctl target,
# and postinst only starts the service.
set -euo pipefail

deb="${1:?Usage: build/smoke-test-deb.sh <audiobookshelf_*_amd64.deb>}"
if [ ! -f "$deb" ]; then
  echo "Debian package not found: $deb"
  exit 1
fi

root="$(mktemp -d)"
dpkg-deb -x "$deb" "$root"
bin="$root/usr/share/audiobookshelf/audiobookshelf"
react_dir="$root/usr/share/audiobookshelf/client-react"

if [ ! -x "$bin" ]; then
  echo "Package binary is missing or not executable: $bin"
  exit 1
fi
if [ ! -f "$react_dir/node_modules/next/package.json" ]; then
  echo "Package is missing the React client runtime: $react_dir"
  exit 1
fi

pids=()
cleanup() {
  local pid
  for pid in "${pids[@]+"${pids[@]}"}"; do
    kill "$pid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

work="$(mktemp -d)"
mkdir -p "$work/config" "$work/metadata"
log="$work/missing.log"

echo ">>> Missing REACT_CLIENT_PATH"
set +e
env -u REACT_CLIENT_PATH \
  HOST=127.0.0.1 \
  PORT=18080 \
  CONFIG_PATH="$work/config" \
  METADATA_PATH="$work/metadata" \
  "$bin" >"$log" 2>&1
status=$?
set -e
if [ "$status" -eq 0 ]; then
  echo "Server stayed up without REACT_CLIENT_PATH"
  cat "$log" || true
  exit 1
fi
if ! grep -q "REACT_CLIENT_PATH is required" "$log"; then
  echo "Missing-path run did not report that REACT_CLIENT_PATH is required"
  cat "$log" || true
  exit 1
fi
echo "Missing REACT_CLIENT_PATH ok"

echo ">>> React client"
react_log="$work/react.log"
env REACT_CLIENT_PATH="$react_dir" \
  HOST=127.0.0.1 \
  PORT=18081 \
  CONFIG_PATH="$work/config" \
  METADATA_PATH="$work/metadata" \
  "$bin" >"$react_log" 2>&1 &
pid=$!
pids+=("$pid")

ready=0
for _ in $(seq 1 240); do
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "React client exited before it was healthy"
    tail -n 120 "$react_log" || true
    exit 1
  fi
  if curl -sf --max-time 5 "http://127.0.0.1:18081/healthcheck" >/dev/null; then
    ready=1
    break
  fi
  sleep 2
done
if [ "$ready" != 1 ]; then
  echo "React client did not become healthy"
  tail -n 120 "$react_log" || true
  exit 1
fi

page="$(curl -sfL --max-time 30 "http://127.0.0.1:18081/")"
if ! printf '%s' "$page" | grep -q '/_next/'; then
  echo "React client page did not contain /_next/"
  tail -n 120 "$react_log" || true
  exit 1
fi

kill "$pid" >/dev/null 2>&1 || true
wait "$pid" >/dev/null 2>&1 || true
echo "React client ok"
echo "Smoke test passed"
