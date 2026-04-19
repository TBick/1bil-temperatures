#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

required_dirs=(
  "${repo_root}/build"
  "${repo_root}/resources"
)

printf 'Initializing local repo directories in %s\n' "${repo_root}"

for dir in "${required_dirs[@]}"; do
  if [[ -d "${dir}" ]]; then
    printf 'Already exists: %s\n' "${dir}"
    continue
  fi

  mkdir -p "${dir}"
  printf 'Created: %s\n' "${dir}"
done

cat <<'EOF'

Local initialization complete.

Next steps:
  1. Build a target with c3c, for example:
     c3c build analyze_temps-debug
  2. Generate local input data if needed:
     ./build/generate_temps-release resources/generated_temperatures.txt 1000 250
EOF
