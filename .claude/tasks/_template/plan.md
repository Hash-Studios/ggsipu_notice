# Plan: <task-id>

## Approach

<How, in a few sentences. Name the files.>

## Steps

1.
2.

## Files expected to change

| Path | Change | Tier it forces (.claude/docs/routing.yaml) |
|---|---|---|
|  |  |  |

## Verification

- Tier: `<fast|normal|full>` — and why that is the honest tier for the files above.
- Command: `tool/harness/verify <tier> --json-out .claude/tasks/<task-id>/verify.json`
- Review: `<none|standard|adversarial>` — and which `review:` path in routing.yaml requires it.

<If a required check cannot run in this environment, say so here BEFORE starting. An
unrunnable required check makes the result `incomplete`, which is not a pass.>

## Risks

<What could go wrong, and what would catch it. If nothing in the repo would catch it, say
that — this repo has no behavioural test coverage (see AGENTS.md, "The honest gap").>
