#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")"
docker compose -f docker-compose.yml down
