#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for gobyted"

  set -- gobyted "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "gobyted" ]; then
  mkdir -p "$GOBYTE_DATA"
  chmod 700 "$GOBYTE_DATA"
  chown -R gobyte "$GOBYTE_DATA"

  echo "$0: setting data directory to $GOBYTE_DATA"

  set -- "$@" -datadir="$GOBYTE_DATA"
fi

if [ "$1" = "gobyted" ] || [ "$1" = "gobyte-cli" ] || [ "$1" = "gobyte-tx" ]; then
  echo
  exec su-exec gobyte "$@"
fi

echo
exec "$@"
