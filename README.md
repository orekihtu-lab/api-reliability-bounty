# API Retry Decision Bounty

This repository is a small deterministic coding task for the Agent Bounties
API-reliability route.

## Task

Fix `solution/retry_decision.sh` so it implements the interface below. Only
changes under `solution/` are part of a submission.

```text
retry_decision.sh STATUS ATTEMPT MAX_ATTEMPTS [RETRY_AFTER_SECONDS]
```

The script must print exactly one decision:

- `success:0` for any HTTP status from 200 through 299.
- `retry:SECONDS` for 408, 425, 429, 500, 502, 503, or 504 while
  `ATTEMPT < MAX_ATTEMPTS`.
- `stop:0` for every other valid HTTP status, and whenever the retry budget is
  exhausted.

For a retry, use `RETRY_AFTER_SECONDS` when it is an integer from 0 through
300. Otherwise use `2^(ATTEMPT-1)` seconds, capped at 60 seconds.

`STATUS` must be an integer from 100 through 599. `ATTEMPT` and
`MAX_ATTEMPTS` must be positive integers with `ATTEMPT <= MAX_ATTEMPTS`.
Invalid input must exit with status 64 and produce no stdout.

## Verification

Run:

```sh
sh benchmark/test.sh
```

The starting implementation intentionally fails the benchmark. A valid fix
must pass every public case without modifying `benchmark/`.

