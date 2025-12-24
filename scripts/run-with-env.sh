#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
usage:
  source run-with-env.sh [-f .env]
USAGE
}

ENV_FILE=".env"

while getopts ":f:h" opt; do
  case "${opt}" in
    f) ENV_FILE="${OPTARG}" ;;
    h) usage; exit 0 ;;
    \?) echo "invalid option: -${OPTARG}" >&2; usage; exit 2 ;;
    :) echo "option -${OPTARG} requires an argument" >&2; usage; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "this script must be sourced to keep env vars in the current shell" >&2
  usage
  exit 2
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "env file not found: ${ENV_FILE}" >&2
  return 2
fi

set -a
. "${ENV_FILE}"
set +a
