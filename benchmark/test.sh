#!/bin/sh
set -eu

if [ -f /workspace/retry_decision.sh ]; then
  subject=/workspace/retry_decision.sh
else
  root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
  subject="$root/solution/retry_decision.sh"
fi
tmp="${TMPDIR:-/tmp}/api-retry-bounty.$$"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp"

failures=0

expect_output() {
  expected=$1
  shift
  if actual=$(sh "$subject" "$@" 2>"$tmp/stderr"); then
    status=0
  else
    status=$?
  fi
  if [ "$status" -ne 0 ] || [ "$actual" != "$expected" ] || [ -s "$tmp/stderr" ]; then
    printf 'FAIL args=%s expected=%s status=%s actual=%s\n' "$*" "$expected" "$status" "$actual" >&2
    failures=$((failures + 1))
  fi
}

expect_invalid() {
  if actual=$(sh "$subject" "$@" 2>"$tmp/stderr"); then
    status=0
  else
    status=$?
  fi
  if [ "$status" -ne 64 ] || [ -n "$actual" ]; then
    printf 'FAIL invalid args=%s expected_status=64 status=%s stdout=%s\n' "$*" "$status" "$actual" >&2
    failures=$((failures + 1))
  fi
}

# Successful responses never retry.
expect_output 'success:0' 200 1 3
expect_output 'success:0' 204 2 3
expect_output 'success:0' 299 3 3 30

# Only the published transient status set retries.
expect_output 'retry:1' 408 1 4
expect_output 'retry:2' 425 2 4
expect_output 'retry:4' 429 3 4
expect_output 'retry:8' 500 4 5
expect_output 'retry:16' 502 5 6
expect_output 'retry:32' 503 6 7
expect_output 'retry:60' 504 7 8

# A valid server Retry-After overrides backoff, including zero and the cap.
expect_output 'retry:0' 429 1 2 0
expect_output 'retry:17' 503 1 2 17
expect_output 'retry:300' 503 1 2 300

# Invalid or excessive Retry-After values fall back to capped exponential delay.
expect_output 'retry:4' 429 3 4 invalid
expect_output 'retry:60' 503 8 9 301

# Permanent failures and exhausted budgets stop.
expect_output 'stop:0' 400 1 5
expect_output 'stop:0' 401 1 5
expect_output 'stop:0' 404 1 5
expect_output 'stop:0' 501 1 5
expect_output 'stop:0' 408 3 3
expect_output 'stop:0' 429 1 1 20
expect_output 'stop:0' 503 5 5
expect_output 'stop:0' 599 1 2

# Inputs fail closed.
expect_invalid
expect_invalid 99 1 3
expect_invalid 600 1 3
expect_invalid abc 1 3
expect_invalid 500 0 3
expect_invalid 500 -1 3
expect_invalid 500 4 3
expect_invalid 500 1 0
expect_invalid 500 1 nope

if [ "$failures" -ne 0 ]; then
  printf '%s benchmark case(s) failed\n' "$failures" >&2
  exit 1
fi

printf '%s\n' 'all API retry decision benchmark cases passed'
