#!/usr/bin/env bash

set -e

exit_with_error() { >&2 echo -e "❌ ${1}"; exit 1; }

if [ -z "${1:-}" ]; then
  exit_with_error "Missing input. Expected key-value pair(s):\n\t> ./$(basename "$0") <key>=<new_value> [<key>=<new_value>, ...]"
fi

set -u

PROJECT_ROOT=$(realpath "${0%/*}/..")
CONFIG_PATH="$PROJECT_ROOT/Config.xcconfig"

for PAIR in "$@"; do
  if [[ "$PAIR" != *=* ]]; then
    exit_with_error "Invalid input format: '$PAIR'. Expected <key>=<value>"
  fi

  IFS='=' read -ra PAIR_ARRAY <<< "$PAIR"
  KEY=${PAIR_ARRAY[0]}
  NEW_VALUE=${PAIR_ARRAY[1]}

  if (! grep -q "^$KEY =" "$CONFIG_PATH"); then
    exit_with_error "Key $KEY not found in $CONFIG_PATH"
  fi

  echo "⚙️ Updating config entry $KEY to \"$NEW_VALUE\" in '$CONFIG_PATH'"

  sed -i '' -e "/$KEY =/ s/= .*/= $NEW_VALUE/" "$CONFIG_PATH"
done
