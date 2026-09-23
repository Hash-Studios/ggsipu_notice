// ggsipu_notice's own file classifier: changed files -> required verification tier.
//
// Repo-specific by design. The shared harness core deliberately ships no classifier,
// because "what does this change risk" is a question only a specific repo can answer.
// This one answers it for a Flutter notice-board app whose Python Cloud Functions
// backend pushes FCM notifications to every installed device. Wrapped by
// .claude/harness/adapter.mjs's classifyChanges.
//
// LOCKSTEP: `.claude/docs/routing.yaml` is the human-readable statement of this same
// policy and `RULES` below is its executable form. Node has no built-in YAML parser and
// this repo has no YAML dependency, so the policy is not parsed from the YAML at runtime.
// Change both files together. Both are listed in POLICY_FILES, so editing either changes
// the verification policy fingerprint and invalidates every existing verify.json — which
// is what makes drift loud instead of silent.

export const TIERS = ["fast", "normal", "full"];
export const TIER_RANK = { fast: 0, normal: 1, full: 2 };

// Files whose content defines what verification means here. Hashed into every
// verify.json's verification_policy_fingerprint. analysis_options.yaml is in the list
// because it defines what `flutter analyze` actually checks; pubspec.yaml because it
// defines the toolchain (flutter_lints, build_runner, json_serializable) those commands
// come from.
export const POLICY_FILES = [
  "tool/harness/verify",
  "tool/harness/lib/classify.mjs",
  "tool/harness/lib/reviewpolicy.mjs",
  ".claude/docs/routing.yaml",
  "analysis_options.yaml",
  "pubspec.yaml",
];

// Never part of a workspace fingerprint: task bookkeeping, managed worktrees, and build
// output. `.dart_tool/`, `build/` and the two Python virtualenvs are gitignored anyway;
// listing them keeps an unrelated `flutter pub get` or `pip install` from invalidating an
// artifact. `ios/Pods/` is here for the same reason.
export const FINGERPRINT_EXCLUDE_PREFIXES = [
  ".claude/tasks/",
  ".claude/worktrees/",
  ".dart_tool/",
  "build/",
  "ios/Pods/",
  "server/venv/",
  "server-new/functions/venv/",
  "server-new/functions/__pycache__/",
];

// Shared resources a worker may serialize on. All four of the runtime's defaults are
// genuinely real here, unlike in a repo with no codegen or no release path:
//   codegen               — build_runner rewrites lib/models/notice.g.dart
//   dependency-resolution — flutter pub get rewrites pubspec.lock and .dart_tool/
//   repo-format           — dart format rewrites source across lib/ and test/
//   release               — firebase deploy / store upload
export const LOCK_RESOURCES = ["codegen", "dependency-resolution", "repo-format", "release"];

// First match wins, in order. Mirrors routing.yaml's `classification:` block.
export const RULES = [
  { match: "server-new/functions/main.py", tier: "full", why: "the scheduled Cloud Function that scrapes, writes Firestore, mirrors to Algolia and sends FCM messages to every installed device — a push notification cannot be un-sent" },
  { match: "server-new/functions/**", tier: "full", why: "the rest of the deployed backend, including the Algolia backfill — same blast radius" },
  { match: "server-new/**", tier: "full", why: "deploy target and extension configuration — these decide what `firebase deploy` does" },
  { match: "lib/main.dart", tier: "full", why: "app bootstrap: Firebase init, the vm:entry-point FCM background handler, OneSignal init, and the write of every device's FCM token into Firestore" },
  { match: "pubspec.yaml", tier: "full", why: "a new dependency ships inside a published mobile app" },
  { match: "pubspec.lock", tier: "full", why: "the resolved dependency graph the shipped build is reproducible against" },
  { match: ".gitignore", tier: "full", why: "the only thing keeping lib/keys.dart, android/app/google-services.json and key.jks out of git history" },
  { match: "android/**", tier: "full", why: "native build configuration and release signing for the published app" },
  { match: "ios/**", tier: "full", why: "native build configuration for the published app" },
  { match: "lib/models/**", tier: "normal", why: "the shape parsed from live production Firestore documents, and the json_serializable source the tracked notice.g.dart must stay in sync with" },
  { match: "lib/services/**", tier: "normal", why: "Firestore and Algolia access, theming, and the GetIt registrations everything else resolves through" },
  { match: "lib/notifiers/**", tier: "normal", why: "the app's ChangeNotifier state, and the bridge between services/ and the UI" },
  { match: "server/**", tier: "normal", why: "the legacy Heroku scraper — superseded by server-new/ and not currently deployed, but still real tracked code" },
  { match: "analysis_options.yaml", tier: "normal", why: "defines what `flutter analyze` actually checks" },
  { match: "tool/harness/**", tier: "normal", why: "verifier, gate and policy logic — also policy files" },
  { match: ".claude/docs/routing.yaml", tier: "normal", why: "the verification policy itself" },
  { match: "AGENTS.md", tier: "normal", why: "the rules agents work from" },
  { match: "lib/pages/**", tier: "fast", why: "one page; presentation over already-fetched notices, covered by analyze" },
  { match: "lib/widgets/**", tier: "fast", why: "presentation only, covered by analyze" },
  { match: "test/**", tier: "fast", why: "tests themselves" },
  { match: "web/**", tier: "fast", why: "created by `flutter create`; nothing ships from it" },
  { match: "windows/**", tier: "fast", why: "created by `flutter create`; nothing ships from it" },
  { match: "assets/**", tier: "fast", why: "bundled images" },
  { match: "icon/**", tier: "fast", why: "launcher icon sources" },
  { match: "demo/**", tier: "fast", why: "README screenshots" },
  { match: "docs/**", tier: "fast", why: "documentation" },
  { match: "README.md", tier: "fast", why: "documentation" },
  { match: ".claude/tasks/**", tier: "fast", why: "task bookkeeping — excluded from fingerprints entirely" },
  { match: "*", tier: "fast", why: "default floor — nothing here is verification-exempt" },
];

const DOUBLESTAR = "__HARNESS_DOUBLESTAR__";

/**
 * Minimal glob matcher for the forms RULES actually uses: an exact path, a `dir/**`
 * prefix, a single `*` segment wildcard, and the bare `*` catch-all. Deliberately not a
 * general glob implementation — a rule form not listed above is a policy authoring
 * mistake, and a silently-mismatching clever matcher would be worse than an obvious one.
 */
export function matchesPattern(path, pattern) {
  if (pattern === "*") return true;
  if (!pattern.includes("*")) return path === pattern;
  if (pattern.endsWith("/**")) {
    const prefix = pattern.slice(0, -2); // keep the trailing slash
    return path.startsWith(prefix);
  }
  const escaped = pattern.replace(/[.+^${}()|[\]\\]/g, "\\$&");
  const body = escaped.split("**").join(DOUBLESTAR).split("*").join("[^/]*").split(DOUBLESTAR).join(".*");
  return new RegExp(`^${body}$`).test(path);
}

/** The tier one path demands, plus the rule that decided it. */
export function classifyFile(path) {
  for (const rule of RULES) {
    if (matchesPattern(path, rule.match)) return { tier: rule.tier, rule: rule.match, why: rule.why };
  }
  // Unreachable while the `*` catch-all is present. Fail closed rather than return
  // undefined if someone ever removes it.
  return { tier: "full", rule: "(no rule matched)", why: "fail closed: no classification rule matched" };
}

/**
 * The highest tier any changed file demands. An EMPTY change set returns "fast" — the
 * floor, not "full": a verify run with nothing changed has nothing to escalate for.
 * Returns { requiredTier, reasons: [{path, tier, rule, why}] } with reasons listing only
 * the files that drove the maximum.
 */
export function classifyChanges(changedFiles) {
  let requiredTier = "fast";
  const all = [];
  for (const path of changedFiles) {
    const c = classifyFile(path);
    all.push({ path, ...c });
    if (TIER_RANK[c.tier] > TIER_RANK[requiredTier]) requiredTier = c.tier;
  }
  return { requiredTier, reasons: all.filter((r) => r.tier === requiredTier) };
}
