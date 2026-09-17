#!/usr/bin/env bash
set -euo pipefail

# Конечный синтетический вывод. Аргумент — количество ASCII-байтов.
python3 - "${1:-1000000}" <<'PY'
import hashlib
import sys

try:
    remaining = int(sys.argv[1])
    if remaining <= 0:
        raise ValueError
except ValueError:
    sys.exit("Usage: flood.sh [positive byte count], default: 1000000")

counter = 0
while remaining:
    lines = []
    for _ in range(1024):
        line = hashlib.sha256(f"demo-event-{counter}".encode("ascii")).hexdigest().encode("ascii") + b"\n"
        chunk = line[:remaining]
        lines.append(chunk)
        remaining -= len(chunk)
        counter += 1
        if not remaining:
            break
    sys.stdout.buffer.write(b"".join(lines))
PY
