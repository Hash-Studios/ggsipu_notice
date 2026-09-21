# Verification — ggsipu_notice

`tool/harness/verify` is this repository's only definition of "passing". There is no CI
(`.github/` holds `FUNDING.yml` and nothing else), no `Makefile` and no task runner, so
nothing else in this repo makes that claim.

```
tool/harness/verify <fast|normal|full> [--base <ref>] [--files a b ...]
                                       [--json-out <path>] [--quiet]
```

Exit 0 only when `result === "passed"`. Exit 1 for `failed` or `incomplete`. Exit 2 when
the verifier itself could not start.

## The rule

A check is reported `passed` only if it actually ran and actually exited zero (or, for an
internal predicate, actually evaluated true). A required check that **could not run** is
`skipped`, is listed in `unsatisfied_required`, and makes the whole run `incomplete` —
never `passed`. "I could not check" and "it is fine" are different answers, and this
verifier keeps them different.

## Tiers

| Check | What it runs | fast | normal | full | Required |
|---|---|:--:|:--:|:--:|:--:|
| `local_config` | `lib/keys.dart` and `lib/firebase_options.dart` are present | ✓ | ✓ | ✓ | yes |
| `secrets` | no credential file is tracked by git or present unignored | ✓ | ✓ | ✓ | yes |
| `format` | `dart format --output=none --set-exit-if-changed lib test` | ✓ | ✓ | ✓ | yes |
| `analyze` | `flutter analyze` | ✓ | ✓ | ✓ | yes |
| `codegen` | `dart run build_runner build --delete-conflicting-outputs`, then assert the tracked `*.g.dart` did not move | | ✓ | ✓ | yes |
| `test` | `flutter test` | | ✓ | ✓ | yes |
| `py_syntax` | `ast.parse` over `server/scraper.py` and `server-new/functions/*.py` | | ✓ | ✓ | yes |
| `build_android` | `flutter build apk --debug` | | | ✓ | yes |

**fast** is the working loop: seconds, and nothing writes to the tree.

**normal** adds the checks that need the Dart toolchain to do real work. Note `codegen`
**writes**: it runs `build_runner`, which rewrites generated files. That is why it is not
in `fast`, and why `codegen` is one of this repo's lock resources
(`.claude/docs/routing.yaml`, `lock_resources:`).

**full** adds the Android debug build — the only check in the whole verifier that
exercises `android/` at all. `flutter analyze` cannot see Gradle config, the manifest or
the signing setup; only a build can.

Which tier a change *requires* is not your choice: `tool/harness/verify` classifies the
changed files itself (`.claude/docs/routing.yaml` / `tool/harness/lib/classify.mjs`) and
records the answer as `required_tier`. The completion gate compares that against the tier
you actually ran. Touching `server-new/functions/main.py` or `lib/main.dart` requires
`full`; touching `lib/widgets/` requires only `fast`.

## Preconditions this repo genuinely has

Four files are gitignored on purpose because they carry credentials, and are simply absent
from a fresh clone:

| File | Blocks |
|---|---|
| `lib/keys.dart` | `analyze`, `test`, `codegen`, `build_android` |
| `lib/firebase_options.dart` | the same |
| `android/app/google-services.json` | `build_android` |
| `key.jks` | release builds (not part of any verifier tier) |

`local_config` reports the first two by name on **every** tier, so the wall of
`uri_does_not_exist` / `undefined_identifier` errors `flutter analyze` produces without
them is never mistaken for a code defect. `build_android` reports the third through its
`available()`, which makes `full` `incomplete` rather than falsely failing.

These are satisfiable preconditions for whoever owns this app — not an unpassable gate.
Supply the files locally, and never commit them: `secrets` enforces that mechanically on
every tier, because a credential in git history is effectively permanent.

## The honest gap

`test/` contains exactly one file, `test/widget_test.dart`, and it is the **unmodified
`flutter create` counter template** — it pumps `MyApp`, then looks for an `Icons.add` and
the text `0`. This app is a `CupertinoApp` rendering a list of notices. The test cannot
pass, and would prove nothing if it did.

So: **this repository has no behavioural test coverage.** Every artifact this verifier
writes carries that sentence in its `coverage_note`, not just this document.

`test` is nevertheless wired in as a **required** check with a real command, because a real
runner and a real test file exist. Marking it `required: false` would quietly bless a suite
that tests nothing. Instead it stands as a recorded baseline failure until the template
test is replaced with tests of this app — at which point the check simply starts passing,
with no change to this verifier.

What a green `full` run therefore does and does not mean:

- **Does** mean: the Dart analyzes clean under `flutter_lints ^4.0.0`, the source is
  formatted, `lib/models/notice.g.dart` matches the `json_serializable` source it is
  generated from, the Python parses under the 3.11 interpreter the Cloud Functions deploy
  to, no credential file is tracked or exposed, and an Android debug APK builds.
- **Does not** mean: any app behaviour is correct. Nothing here exercises the Firestore
  query, the Algolia search, notification handling, or the scraper's dedupe logic.

## Baseline at bootstrap (2026-09-21, commit `b31e090`)

`tool/harness/verify fast` failed on this repo's pre-existing state. These are recorded,
not fixed — the harness install does not touch application code, style or tests:

| Check | Result | Why |
|---|---|---|
| `local_config` | **failed** | `lib/keys.dart` and `lib/firebase_options.dart` are absent (gitignored, never committed) |
| `secrets` | passed | nothing credential-bearing is tracked or exposed |
| `format` | **failed** | 8 of 19 files are not `dart format`-clean: `lib/main.dart`, `lib/models/notice.dart`, `lib/pages/home_page.dart`, `lib/services/firestore_service.dart`, `lib/services/logger.dart`, `lib/services/theme_service.dart`, `lib/widgets/error_sliver.dart`, `lib/widgets/notice_tile.dart` |
| `analyze` | **failed** | 14 issues — 7 errors, all downstream of the missing `lib/keys.dart`, plus 7 infos (`prefer_const_constructors` in `error_sliver.dart`, `unnecessary_import` in `go_to_top_fab.dart`) |

At `normal`, `test` also fails: `flutter test` cannot even compile `test/widget_test.dart`,
again because of the missing `lib/keys.dart`.

Supplying `lib/keys.dart` and `lib/firebase_options.dart` clears the `local_config` failure
and all 7 analyze errors. The 7 analyze infos, the 8 unformatted files and the template
test are genuine pre-existing work, independent of the harness.

## Artifacts

`--json-out <path>` writes the result. **Never hand-write one** — a `verify.json` is
evidence that the verifier ran, and the completion gate exists to tell evidence from a
claim. Fields the gate reads:

| Field | Meaning |
|---|---|
| `result` | `passed` \| `failed` \| `incomplete` |
| `completion_tier_satisfied` | true only when `result === "passed"` |
| `unsatisfied_required` | required checks that could not run, with the reason |
| `required_tier` | what the classifier says this change needs |
| `tier` | what was actually run |
| `verification_policy_fingerprint` | sha256 over `POLICY_FILES` — changing policy invalidates old artifacts |
| `workspace_fingerprint` | sha256 over the changed files — editing after verifying invalidates it |
| `verification_scope` | `default`, `base` or `files` — a `--files` run proves only those files |
| `coverage_note` | the honest gap, in the artifact itself |

## Independent review

Optional here, and required on only five paths (`.claude/docs/routing.yaml`, `review:`).
`tool/harness/review run` pins `gpt-5.6-sol` via the Codex CLI; override with
`GGSIPU_NOTICE_REVIEW_MODEL`. If the CLI is absent, unauthenticated, on the wrong model or
fails mid-run, it writes an `incomplete` `review.json` carrying the reason and exits
non-zero. There is no path from "review unavailable" to "review passed".
