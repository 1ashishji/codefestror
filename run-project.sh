#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

compose=(docker-compose)

if ! docker ps >/dev/null 2>&1; then
  if [[ ! -t 0 ]]; then
    echo "Docker requires sudo on this machine. Run this script from your terminal so sudo can ask for your password." >&2
    exit 1
  fi

  compose=(sudo docker-compose)
fi

echo "Cleaning old Compose containers without deleting volumes..."
"${compose[@]}" -p test down --remove-orphans || true
"${compose[@]}" down --remove-orphans || true

echo "Starting project..."
"${compose[@]}" up --build --force-recreate
