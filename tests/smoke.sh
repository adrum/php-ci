#!/bin/sh
# Runs inside the built image and fails if anything CI jobs rely on is missing.
set -eu

php -v

modules=$(php -m)
for ext in intl bcmath pcov zip pdo_sqlite pdo_mysql pdo_pgsql mbstring gd exif pcntl redis; do
    if ! printf '%s\n' "$modules" | grep -qix "$ext"; then
        echo "missing extension: $ext" >&2
        exit 1
    fi
done

composer --version
git --version
unzip -v | head -n 1
curl --version | head -n 1
jq --version
mysql --version
psql --version

echo "smoke test passed"
