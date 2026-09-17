#!/usr/bin/env bash
set -euo pipefail

EXPERIMENT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEMO_ROOT="$(mktemp -d /tmp/podlodka-workspace-escape.XXXXXX)"
cp -R "$EXPERIMENT_DIR/fixture/." "$DEMO_ROOT/"
printf '%s\n' "$DEMO_ROOT/repo"
