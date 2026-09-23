// ggsipu_notice's verification check table — moved verbatim (only the calling convention
// changed: `{ cwd }` -> `ctx` with `ctx.root`, to match the v2 adapter API's Check shape)
// from tool/harness/verify's inline CHECKS/TIER_CHECKS table.
//
// Every spawned entry names a real command in this repo's toolchain (AGENTS.md records
// where each came from: pubspec.yaml, analysis_options.yaml, server-new/firebase.json).
// There is no CI file and no Makefile in this repo, so this table is the only definition
// of "passing" it has.
//
// `available(ctx)` returns null when the check can run, or a human reason string when it
// genuinely cannot — that reason is what lands in unsatisfied_required.

import { spawnSync, execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";

// Local config this repo deliberately gitignores. Absent from a fresh clone, and the app
// does not analyze, test or build without them. Listed with what each one is for so a
// failure explains itself.
const LOCAL_CONFIG = [
  { path: "lib/keys.dart", why: "oneSignalAppID, algoliaApplicationId, algoliaApiKey — imported by lib/main.dart and lib/services/algolia_service.dart" },
  { path: "lib/firebase_options.dart", why: "FlutterFire configuration — generate with `flutterfire configure`" },
];

// Secrets .gitignore excludes. A leak into git history is effectively permanent, so this
// is checked on every tier rather than left to review.
const SECRET_PATHS = [
  "lib/keys.dart",
  "lib/firebase_options.dart",
  "android/app/google-services.json",
  "key.jks",
  "keys.py",
  "config.py",
  "server/ggsipu-notice-firebase-adminsdk-4c8gx-3fb2a73c7b.json",
];

// Python sources that are actually ours. venv/ and __pycache__/ are excluded: they are
// third-party bytes and build output, and server-new/firebase.json already ignores them
// at deploy time.
const PY_SOURCES = ["server/scraper.py", "server-new/functions/main.py", "server-new/functions/backfill_algolia.py"];

const CHECK_TIMEOUT_MS = 15 * 60 * 1000;

function which(bin) {
  const r = spawnSync("command", ["-v", bin], { encoding: "utf8", shell: true });
  return r.status === 0 && (r.stdout ?? "").trim() !== "" ? (r.stdout ?? "").trim().split("\n")[0] : null;
}

function flutterAvailable() {
  return which("flutter") ? null : "the `flutter` command is not on PATH — install Flutter (this repo needs >=3.4.0 per pubspec.yaml's sdk constraint)";
}

function dartAvailable() {
  return which("dart") ? null : "the `dart` command is not on PATH";
}

function packagesResolved(root) {
  if (!existsSync(join(root, ".dart_tool", "package_config.json"))) {
    return "dependencies are not resolved — run `flutter pub get` (.dart_tool/package_config.json is missing)";
  }
  return null;
}

/** The Python this repo's Cloud Functions actually target (server-new/firebase.json says
 *  "runtime": "python311"). Prefer the checked-in venv's 3.11 over whatever `python3` is,
 *  so a syntax check reflects the deployed interpreter. */
function pythonInterpreter(root) {
  const venv = join(root, "server-new", "functions", "venv", "bin", "python3.11");
  if (existsSync(venv)) return { bin: venv, label: "server-new/functions/venv/bin/python3.11 (matches firebase.json's python311 runtime)" };
  const sys = which("python3");
  if (sys) return { bin: sys, label: `${sys} (system python3 — NOT the python311 runtime the functions deploy to)` };
  return null;
}

function git(root, args) {
  return execFileSync("git", args, { cwd: root, encoding: "utf8", maxBuffer: 32 * 1024 * 1024, stdio: ["ignore", "pipe", "pipe"] });
}

// --- Internal checks -----------------------------------------------------------------
// Three of this repo's real risks are not expressible as a command from its toolchain, so
// they are predicates instead. All three are deterministic and explain themselves.

/**
 * `lib/keys.dart` and `lib/firebase_options.dart` are gitignored on purpose (they carry
 * the OneSignal app id, the Algolia credentials and the Firebase config) and are simply
 * absent from a fresh clone. Without them `flutter analyze` and `flutter test` fail with
 * `uri_does_not_exist`, which reads like a code error and is not one. This check names
 * the real cause first, on every tier, so nobody debugs the wrong thing.
 */
function checkLocalConfig({ root }) {
  const missing = LOCAL_CONFIG.filter((f) => !existsSync(join(root, f.path)));
  if (missing.length === 0) {
    return { ok: true, detail: `${LOCAL_CONFIG.map((f) => f.path).join(", ")} are present` };
  }
  return {
    ok: false,
    detail:
      `these gitignored local-config files are missing:\n` +
      missing.map((f) => `  ${f.path} — ${f.why}`).join("\n") +
      `\n\nThey are excluded by .gitignore ON PURPOSE and must stay that way; supply them\n` +
      `locally. Until then \`flutter analyze\` and \`flutter test\` will report\n` +
      `uri_does_not_exist / undefined_identifier against lib/main.dart and\n` +
      `lib/services/algolia_service.dart, and those failures are this, not a code defect.`,
  };
}

/**
 * The credential files .gitignore excludes must be neither tracked by git nor sitting in
 * the working tree unignored. Git history is the one place a leak here is permanent, and
 * one `git add -A` is all it takes.
 */
function checkSecrets({ root }) {
  let tracked = [];
  try {
    tracked = git(root, ["ls-files", "--", ...SECRET_PATHS, "*.jks", "*.keystore"]).split("\n").filter(Boolean);
  } catch (e) {
    return { ok: false, detail: `could not ask git which credential files are tracked: ${String(e.message ?? e)}` };
  }
  if (tracked.length > 0) {
    return {
      ok: false,
      detail:
        `these credential files are TRACKED by git:\n${tracked.map((t) => `  ${t}`).join("\n")}\n` +
        `They carry Firebase / Algolia / OneSignal credentials or the release signing key.\n` +
        `Untrack them (git rm --cached <file>) and keep .gitignore's rules for them intact.`,
    };
  }
  // --exclude-standard is load-bearing: without it, `ls-files --others` lists IGNORED
  // files too, so every correctly-gitignored key file would be reported as a leak.
  let present = [];
  try {
    present = git(root, ["ls-files", "--others", "--exclude-standard", "--", ...SECRET_PATHS, "*.jks", "*.keystore"]).split("\n").filter(Boolean);
  } catch {
    present = [];
  }
  if (present.length > 0) {
    return {
      ok: false,
      detail:
        `these credential files are untracked but NOT ignored:\n${present.map((p) => `  ${p}`).join("\n")}\n` +
        `One \`git add -A\` would commit them. Restore the matching .gitignore rule.`,
    };
  }
  return { ok: true, detail: "no credential file is tracked, and none is present unignored" };
}

/**
 * `lib/models/notice.g.dart` is json_serializable's output and is tracked in git. If
 * `notice.dart` changed and the committed `.g.dart` was not regenerated, the app parses
 * live Firestore documents with a stale schema. Regenerates and asserts nothing moved.
 *
 * This check WRITES: it runs build_runner, which rewrites generated files in the tree.
 * That is why it is in `normal`/`full` and not in the `fast` working loop, and why
 * `codegen` is one of this repo's lock resources.
 */
function checkCodegen({ root }) {
  const before = (() => {
    try {
      return git(root, ["status", "--porcelain=v1", "--", "*.g.dart"]);
    } catch (e) {
      return `<unavailable: ${String(e.message ?? e)}>`;
    }
  })();

  const r = spawnSync("dart", ["run", "build_runner", "build", "--delete-conflicting-outputs"], {
    cwd: root,
    encoding: "utf8",
    timeout: CHECK_TIMEOUT_MS,
    maxBuffer: 64 * 1024 * 1024,
  });
  if (r.error || r.signal) {
    // Did not evaluate. Thrown so the caller records it as "skipped", not a pass and not
    // a failure — see adapter.mjs's buildVerificationPlan run() wiring.
    throw new Error(`build_runner did not run: ${r.error?.message ?? `killed by ${r.signal}`}`);
  }
  if (r.status !== 0) {
    return { ok: false, detail: `\`dart run build_runner build --delete-conflicting-outputs\` exited ${r.status}:\n${`${r.stdout ?? ""}${r.stderr ?? ""}`.trimEnd()}` };
  }

  let after;
  try {
    after = git(root, ["status", "--porcelain=v1", "--", "*.g.dart"]);
  } catch (e) {
    return { ok: false, detail: `build_runner succeeded but git could not report generated-file status: ${String(e.message ?? e)}` };
  }
  if (after !== before) {
    return {
      ok: false,
      detail:
        `regenerating changed the committed output — the tracked *.g.dart files are stale.\n` +
        `git status for *.g.dart before:\n${before || "  (clean)"}\nafter:\n${after || "  (clean)"}\n` +
        `Run \`dart run build_runner build --delete-conflicting-outputs\` and commit the result.`,
    };
  }
  return { ok: true, detail: "build_runner produced no change to the tracked *.g.dart files" };
}

/**
 * A real syntax check over this repo's own Python, using the interpreter the functions
 * actually deploy to where one is available. `ast.parse` rather than `py_compile` so the
 * check writes no bytecode into the tree.
 *
 * This is the WHOLE of the Python checking this repo can honestly do: ruff, black, mypy
 * and pytest are not installed and are declared nowhere (server/requirements.txt and
 * server-new/functions/requirements.txt list neither). A check claiming more would be
 * inventing a toolchain this repo does not have.
 */
function checkPySyntax({ root }) {
  const interp = pythonInterpreter(root);
  if (!interp) throw new Error("no python3 interpreter found"); // -> skipped, not a pass
  const present = PY_SOURCES.filter((p) => existsSync(join(root, p)));
  if (present.length === 0) return { ok: true, detail: "no Python sources present" };
  const r = spawnSync(
    interp.bin,
    ["-c", "import ast,sys\nfor f in sys.argv[1:]:\n    ast.parse(open(f, encoding='utf-8').read(), filename=f)\n", ...present],
    { cwd: root, encoding: "utf8", timeout: CHECK_TIMEOUT_MS, maxBuffer: 16 * 1024 * 1024 },
  );
  if (r.error || r.signal) throw new Error(`could not run ${interp.bin}: ${r.error?.message ?? `killed by ${r.signal}`}`);
  if (r.status !== 0) return { ok: false, detail: `${`${r.stdout ?? ""}${r.stderr ?? ""}`.trimEnd()}\n\n(parsed with ${interp.label})` };
  return { ok: true, detail: `parsed ${present.length} file(s) with ${interp.label}` };
}

function asRunResult(r) {
  return r.ok ? { status: "passed", detail: r.detail ?? "" } : { status: "failed", detail: r.detail ?? "" };
}

export const CHECKS = {
  local_config: {
    description: "gitignored lib/keys.dart and lib/firebase_options.dart are present",
    required: true,
    available: () => null,
    run: async (ctx) => asRunResult(checkLocalConfig({ root: ctx.root })),
  },
  secrets: {
    description: "no credential file is tracked or present unignored",
    required: true,
    available: () => null,
    run: async (ctx) => asRunResult(checkSecrets({ root: ctx.root })),
  },
  format: {
    cmd: ["dart", ["format", "--output=none", "--set-exit-if-changed", "lib", "test"]],
    description: "dart format --output=none --set-exit-if-changed lib test",
    required: true,
    available: () => dartAvailable(),
  },
  analyze: {
    cmd: ["flutter", ["analyze"]],
    description: "flutter analyze (lints from analysis_options.yaml / flutter_lints ^4.0.0)",
    required: true,
    available: (ctx) => flutterAvailable() ?? packagesResolved(ctx.root),
  },
  codegen: {
    description: "the tracked lib/models/*.g.dart match their json_serializable sources",
    required: true,
    available: (ctx) => dartAvailable() ?? packagesResolved(ctx.root),
    run: async (ctx) => asRunResult(checkCodegen({ root: ctx.root })),
  },
  test: {
    // A real runner and a real test file exist, so this is required: true. It is also,
    // today, guaranteed to fail — test/widget_test.dart is the unmodified `flutter
    // create` counter template (it pumps MyApp and looks for a `+` icon and the text
    // `0`), and this app is a CupertinoApp showing a notice list.
    //
    // That is recorded as a BASELINE FAILURE, not papered over: marking it required:
    // false would quietly bless a suite that tests nothing, and the point of this check
    // is that the gap stays visible in every artifact until the template test is
    // replaced with tests of this app. See AGENTS.md, "The honest gap".
    cmd: ["flutter", ["test"]],
    description: "flutter test",
    required: true,
    available: (ctx) => flutterAvailable() ?? packagesResolved(ctx.root),
  },
  py_syntax: {
    description: "server/ and server-new/functions/ Python parses (no linter exists in this repo)",
    required: true,
    available: (ctx) => (pythonInterpreter(ctx.root) ? null : "no python3 interpreter is on PATH and server-new/functions/venv is absent"),
    run: async (ctx) => asRunResult(checkPySyntax({ root: ctx.root })),
  },
  build_android: {
    // The only check that exercises android/ at all. Needs the gitignored
    // google-services.json, which is a genuine, satisfiable precondition for the owner —
    // not an unpassable gate. When it is absent this reports "skipped" and, being
    // required, makes the full tier "incomplete": honest about what was not proven.
    cmd: ["flutter", ["build", "apk", "--debug"]],
    description: "flutter build apk --debug",
    required: true,
    available: (ctx) => {
      const base = flutterAvailable() ?? packagesResolved(ctx.root);
      if (base) return base;
      if (!existsSync(join(ctx.root, "android", "app", "google-services.json"))) {
        return "android/app/google-services.json is missing (gitignored) — the Android build cannot be configured without it";
      }
      return null;
    },
  },
};

// Per docs/agents/verification.md's tier table, and routing.yaml's `tiers:` block.
export const TIER_CHECKS = {
  // local_config and secrets are in `fast` deliberately. Both cost milliseconds.
  // local_config is what turns a confusing wall of uri_does_not_exist errors into one
  // sentence, and secrets guards an irreversible leak — a millisecond guard on a
  // permanent risk belongs in every tier, including the one the working loop reruns.
  fast: ["local_config", "secrets", "format", "analyze"],
  normal: ["local_config", "secrets", "format", "analyze", "codegen", "test", "py_syntax"],
  full: ["local_config", "secrets", "format", "analyze", "codegen", "test", "py_syntax", "build_android"],
};

// Stated in every artifact, not just the docs: a green run here is not behavioural
// coverage. See docs/agents/verification.md, "The honest gap".
export const COVERAGE_NOTE =
  "test/ contains one file and it is the unmodified `flutter create` counter template, " +
  "which does not match this app. This repository therefore has NO behavioural test " +
  "coverage. A passing result means the code analyzes clean, is formatted, its generated " +
  "*.g.dart match their sources, its Python parses, no credential file is tracked, and " +
  "(at full) an Android debug APK builds. It does NOT mean any app behaviour is correct.";
