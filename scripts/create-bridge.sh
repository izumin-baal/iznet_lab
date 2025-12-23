#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
usage:
  create-bridge.sh <bridge-name>
  create-bridge.sh -f <clab.yml>
USAGE
}

extract_bridges() {
  local clab_file="$1"
  awk '
    BEGIN { in_nodes=0; current="" }
    /^  nodes:/ { in_nodes=1; next }
    /^  links:/ { in_nodes=0; next }
    in_nodes && $0 ~ /^[ ]{4}[^[:space:]]+:/ {
      current=$0
      sub(/^[ ]{4}/, "", current)
      sub(/:.*/, "", current)
      next
    }
    in_nodes && $0 ~ /^[ ]{6}kind:[ ]*bridge/ {
      if (current != "") { print current }
    }
  ' "${clab_file}"
}

create_bridge() {
  local name="$1"
  if ip link show "${name}" >/dev/null 2>&1; then
    echo "${name} already exists"
    return 0
  fi
  sudo ip link add "${name}" type bridge
  sudo ip link set "${name}" up
  echo "created ${name}"
}

CLAB_FILE=""

while getopts ":f:h" opt; do
  case "${opt}" in
    f) CLAB_FILE="${OPTARG}" ;;
    h) usage; exit 0 ;;
    \?) echo "invalid option: -${OPTARG}" >&2; usage; exit 2 ;;
    :) echo "option -${OPTARG} requires an argument" >&2; usage; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [[ -n "${CLAB_FILE}" ]]; then
  if [[ $# -ne 0 ]]; then
    usage
    exit 2
  fi
  if [[ ! -f "${CLAB_FILE}" ]]; then
    echo "clab file not found: ${CLAB_FILE}" >&2
    exit 2
  fi
  mapfile -t bridges < <(extract_bridges "${CLAB_FILE}")
  if [[ ${#bridges[@]} -eq 0 ]]; then
    echo "no bridge nodes found in ${CLAB_FILE}"
    exit 0
  fi
  for br in "${bridges[@]}"; do
    create_bridge "${br}"
  done
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

create_bridge "$1"
