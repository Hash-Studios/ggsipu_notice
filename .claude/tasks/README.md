# Tasks

One directory per task: `.claude/tasks/<task-id>/`. `.claude/tasks/.active` names the one
task currently in progress (at most one). `_template/` is the skeleton new tasks are seeded
from and is never itself a task.

## Lifecycle

```
tool/harness/task start <task-id> [--tier fast|normal|full] [--review none|standard|adversarial]
tool/harness/task state <planning|working|awaiting_user|verifying|reviewing>
tool/harness/task ready
tool/harness/task complete
tool/harness/task show [--json] | list | abandon
```

States run `planning -> working -> verifying -> [reviewing] -> ready_to_complete -> complete`.
`awaiting_user` is a legal pause from anywhere.

`complete` is **gated**, not asserted. It runs the completion gate and refuses unless the
gate allows. There is no `--force`. The gate wants a `verify.json` that

- actually passed,
- covers the change (its scope matches what is different from the base),
- ran every check its tier requires,
- is still fresh for the workspace (its fingerprints match the tree as it stands now), and
- was produced under the current verification policy.

Ordinary answers, questions, pauses and planning are never gated — the gate only engages
when a task is active.

## What lives in a task directory

| File | Written by | What it is |
|---|---|---|
| `brief.md` | you | what is being asked for, and what done means |
| `plan.md` | you | how it will be done, and what will be verified |
| `decisions.md` | you | numbered decisions (`D1`, `D2`, …), referenced by id from `adjudication.json` |
| `state.json` | `tool/harness/task` only | lifecycle state — never hand-edit |
| `verify.json` | `tool/harness/verify --json-out` only | the verification result |
| `review.json` | `tool/harness/review run` only | the independent review, when one is required |
| `adjudication.json` | `tool/harness/review adjudicate` only | how each blocking finding was resolved |

**Never hand-write `state.json`, `verify.json`, `review.json` or `adjudication.json`.** They
are evidence that a tool ran. A file written by hand is a claim, and the gate exists
precisely to tell the two apart.

## Tier and review mode

`--tier` is your declaration; `tool/harness/verify` independently classifies the changed
files (`.claude/docs/routing.yaml`) and records what the change actually requires. If you
declared `fast` and then touched `server-new/functions/main.py`, the gate blocks — the
classifier wins.

`--review` works the same way: the task may demand a stricter review than policy requires,
never a weaker one. Most changes in this repo need no review at all; see `review:` in
`.claude/docs/routing.yaml` for the five paths that do.

## Task ids

Short, kebab-case, and descriptive of the change: `fix-fcm-token-refresh`,
`replace-template-widget-test`, `algolia-index-rename`. One task at a time.
