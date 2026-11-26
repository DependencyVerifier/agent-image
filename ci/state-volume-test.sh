#!/bin/sh
# Regression test: on a fresh named volume, the non-root agent must be able to write its state (/var/lib/agent).
# `fingerprint` opens the state directory and creates the agent key, without any network access.
#   ci/state-volume-test.sh <image>
set -eu

image="${1:?usage: $0 <image>}"
volume="depverify-state-test-$$"
trap 'docker volume rm -f "$volume" >/dev/null' EXIT

if ! output="$(docker run --rm --read-only --cap-drop ALL --security-opt no-new-privileges:true \
    -e AGENT_CONSOLE_URL=https://console.example.com \
    -e AGENT_CONSOLE_PUBKEY="ed25519:NAIxniyZb4V1/SnznUM1hKGLiMniWNnllw4BcjCf1tM=" \
    -e AGENT_TOKEN=x \
    -v "$volume:/var/lib/agent" \
    "$image" fingerprint 2>&1)"; then
  printf '%s\n' "$output" >&2
  echo "the agent could not start on a fresh state volume" >&2
  exit 1
fi
printf '%s\n' "$output"
if printf '%s\n' "$output" | grep -q 'Permission denied'; then
  echo "the agent could not write its state directory" >&2
  exit 1
fi

owner="$(docker run --rm -v "$volume:/v" alpine:3 stat -c '%u:%g %a' /v)"
echo "state volume: ${owner}"
if [ "$owner" != "65532:65532 700" ]; then
  echo "expected the state volume to be 65532:65532 700" >&2
  exit 1
fi
