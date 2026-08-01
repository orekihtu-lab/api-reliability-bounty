#!/bin/sh

# Intentionally incomplete starting point for the paid child bounty.
status=${1:-}
attempt=${2:-}
max_attempts=${3:-}
retry_after=${4:-}

case "$status:$attempt:$max_attempts" in
  *[!0-9:]*|:*|*::*|*:|*:) exit 64 ;;
esac

if [ "$status" -ge 200 ] && [ "$status" -le 299 ]; then
  printf '%s\n' 'success:0'
elif [ "$status" -ge 400 ] && [ "$status" -le 599 ]; then
  # BUG: retries permanent failures, ignores the retry budget, and accepts an
  # unbounded Retry-After value. The bounty solver must implement the spec.
  if [ -n "$retry_after" ]; then
    delay=$retry_after
  else
    delay=$((2 ** (attempt - 1)))
  fi
  printf 'retry:%s\n' "$delay"
else
  printf '%s\n' 'stop:0'
fi

