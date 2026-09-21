// ggsipu_notice's own review policy: changed files -> required independent-review mode.
//
// Repo-specific by design (the generic runtime ships no review policy — see
// ~/.claude/harness/runtime/README.md's "Left out" section).
//
// The judgement encoded here is narrow and deliberate. Review is requested only where a
// mistake escapes the checkout it was made in. In this repository that is exactly five
// places:
//
//   1. `server-new/functions/main.py` — the scheduled Cloud Function that scrapes GGSIPU's
//      notice page and sends FCM messages. A push notification cannot be un-sent: a
//      dedupe or diff bug notifies every installed device, repeatedly, and no amount of
//      fixing afterwards recalls it.
//   2. `lib/main.dart` — Firebase/OneSignal/FCM setup, the two vm:entry-point handlers,
//      and the write of every device's FCM token into the `fcm_tokens` collection. Break
//      it and notifications break for everyone running the published build.
//   3. `.gitignore` — the only guard keeping `lib/keys.dart`,
//      `android/app/google-services.json` and `key.jks` out of git history, where a
//      credential leak is effectively permanent. The `secrets` check in
//      `tool/harness/verify` catches a secret already present in the tree on EVERY tier,
//      which is a stronger guarantee — but only review catches a rule deleted ahead of
//      the file arriving.
//   4. `android/app/build.gradle` — `signingConfigs.release` for the published app.
//   5. `pubspec.yaml` — a new dependency is third-party code shipped inside a mobile app
//      that holds Firebase credentials. A lockfile-only change (`pubspec.lock`) is
//      mechanical and is deliberately NOT gated.
//
// Those five, and nothing else. `server/` is absent on purpose: it is the legacy Heroku
// scraper, superseded by server-new/ and not currently deployed, so a mistake there
// reaches nobody.
//
// LOCKSTEP with `.claude/docs/routing.yaml`'s `review:` block — see the same note in
// classify.mjs.

import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { join } from "node:path";

import { matchesPattern } from "./classify.mjs";

export const REVIEW_MODES = ["none", "standard", "adversarial"];
export const MODE_RANK = { none: 0, standard: 1, adversarial: 2 };

// Files whose content defines what review means here. Hashed into a review.json's
// review_policy_fingerprint.
export const REVIEW_POLICY_FILES = ["tool/harness/lib/reviewpolicy.mjs", "tool/harness/review", ".claude/docs/routing.yaml"];

export const IRREVERSIBLE_PATH_PATTERNS = [
  { match: "server-new/functions/main.py", mode: "standard", why: "sends FCM pushes to every installed device; a push cannot be un-sent" },
  { match: "lib/main.dart", mode: "standard", why: "FCM/OneSignal setup and the fcm_tokens write that every device depends on" },
  { match: ".gitignore", mode: "standard", why: "guards lib/keys.dart, android/app/google-services.json and key.jks from git history" },
  { match: "android/app/build.gradle", mode: "standard", why: "release signing configuration for the published app" },
  { match: "pubspec.yaml", mode: "standard", why: "a new dependency is third-party code shipped inside a published mobile app" },
];

export const DEFAULT_MODE = "none";

export function maxMode(a, b) {
  return MODE_RANK[a] >= MODE_RANK[b] ? a : b;
}

/** { mode, reasons:[{path, mode, why}] } — reasons lists only files at the max mode. */
export function requiredReviewMode(changedFiles) {
  let mode = DEFAULT_MODE;
  const hits = [];
  for (const path of changedFiles) {
    for (const rule of IRREVERSIBLE_PATH_PATTERNS) {
      if (matchesPattern(path, rule.match)) {
        hits.push({ path, mode: rule.mode, why: rule.why });
        mode = maxMode(mode, rule.mode);
        break;
      }
    }
  }
  return { mode, reasons: hits.filter((h) => h.mode === mode) };
}

/** sha256 over REVIEW_POLICY_FILES' bytes. A missing file hashes as absent, not zero. */
export function reviewPolicyFingerprint({ cwd, policyFiles = REVIEW_POLICY_FILES }) {
  const h = createHash("sha256");
  const sep = Buffer.from([0]);
  for (const rel of [...policyFiles].sort()) {
    h.update(rel);
    h.update(sep);
    try {
      h.update(readFileSync(join(cwd, rel)));
    } catch {
      h.update("<absent>");
    }
    h.update(sep);
  }
  return `sha256:${h.digest("hex")}`;
}
