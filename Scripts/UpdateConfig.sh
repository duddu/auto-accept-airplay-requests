#!/usr/bin/env bash

set -e

if [ -z "${1:-}" ]; then
  >&2 echo '❌ At least one key-value pair required as input'
  >&2 echo -e "\n\t$ $(basename "$0") <key>=<new_value> [<key>=<new_value>, ...]\n"
  exit 1
fi

set -u

PROJECT_ROOT=$(realpath "${0%/*}/..")
CONFIG_PATH="$PROJECT_ROOT/Config.xcconfig"

for PAIR in "$@"; do
  if [[ "$PAIR" != *=* ]]; then
    >&2 echo "❌ Invalid input format: $PAIR. Expected <key>=<value>"; exit 1
  fi

  IFS='=' read -ra PAIR_ARRAY <<< "$PAIR"
  KEY=${PAIR_ARRAY[0]}
  NEW_VALUE=${PAIR_ARRAY[1]}

  if (! grep -q "^$KEY =" "$CONFIG_PATH"); then
    >&2 echo "❌ Key $KEY not found in $CONFIG_PATH"; exit 1
  fi

  echo "⚙️ Updating config entry $KEY to \"$NEW_VALUE\" in $CONFIG_PATH"

  sed -i '' -e "/$KEY =/ s/= .*/= $NEW_VALUE/" "$CONFIG_PATH"
done
