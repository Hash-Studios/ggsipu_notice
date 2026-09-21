// Builds the text packet handed to the independent reviewer, and the two fingerprints
// the completion gate compares it against.
//
// Repo-local on purpose: the generic runtime deliberately does not ship a packet builder,
// because knowing which files are machine-written is a per-repo fact (see
// ~/.claude/harness/runtime/README.md's "Left out"). This one knows which files in THIS
// repo are generated.
//
// Determinism is the whole contract here: `buildPacket` must produce byte-identical
// output for an unchanged workspace, or every review goes stale on the next gate check.
// Nothing time-, path-, or environment-dependent may enter the packet text.

import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// Machine-written files that are tracked in this repo. `*.g.dart` is json_serializable's
// output (`lib/models/notice.g.dart`) — reviewing it wastes the reviewer's attention,
// because the human decision it encodes lives in `notice.dart`, which IS reviewed, and
// `tool/harness/verify`'s `codegen` check already proves the two agree. `pubspec.lock` is
// excluded for the same reason: pub writes it; the decision lives in `pubspec.yaml`.
const GENERATED_RE = /\.g\.dart$|(?:^|\/)pubspec\.lock$/;

const MAX_DIFF_BYTES = 400 * 1024;

export function sha256Hex(s) {
  return createHash("sha256").update(s).digest("hex");
}

export function fingerprintOf(text) {
  return `sha256:${sha256Hex(text)}`;
}

function readOr(path, fallback) {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return fallback;
  }
}

/**
 * The brief/plan content the review was produced against. Kept separate from the packet
 * fingerprint so the gate can tell "the code changed" from "the task's own definition of
 * done changed" — both invalidate a review, for different reasons.
 */
export function reviewInputContentFingerprint({ cwd, taskId }) {
  const dir = join(cwd, ".claude", "tasks", taskId);
  const brief = readOr(join(dir, "brief.md"), "<absent>");
  const plan = readOr(join(dir, "plan.md"), "<absent>");
  return fingerprintOf(`v1\nbrief\n${brief}\nplan\n${plan}\n`);
}

/**
 * The reviewer's input. Returns the packet text; `fingerprintOf(text)` is what lands in
 * review.json's `review_input_fingerprint`.
 */
export function buildPacket({ cwd, taskId, base, changedEntries, mode, tier }) {
  const dir = join(cwd, ".claude", "tasks", taskId);
  const reviewable = changedEntries.filter((e) => !GENERATED_RE.test(e.path));
  const excluded = changedEntries.filter((e) => GENERATED_RE.test(e.path));

  let diff = "";
  try {
    diff = execFileSync("git", ["diff", "-M", base, "--", ...reviewable.map((e) => e.path)], {
      cwd,
      encoding: "utf8",
      maxBuffer: 64 * 1024 * 1024,
      stdio: ["ignore", "pipe", "pipe"],
    });
  } catch (e) {
    diff = `<diff unavailable: ${String(e.message ?? e).split("\n")[0]}>`;
  }
  if (diff.length > MAX_DIFF_BYTES) {
    diff = `${diff.slice(0, MAX_DIFF_BYTES)}\n...[diff truncated at ${MAX_DIFF_BYTES} bytes]`;
  }

  const lines = [
    "# Independent review packet — ggsipu_notice",
    "",
    "ggsipu_notice is a Flutter app (package name `ip_notices`) that lists notices scraped",
    "from GGSIPU's website. Notices live in Cloud Firestore, are mirrored into Algolia for",
    "search, and new ones are pushed to devices over FCM and OneSignal. A scheduled Python",
    "Cloud Function in `server-new/functions/` does the scraping and the pushing.",
    "",
    "Review is requested here only for the surfaces where a mistake escapes the checkout:",
    "",
    "1. `server-new/functions/main.py` — it sends FCM messages to EVERY installed device.",
    "   A push notification cannot be un-sent. Weigh dedupe, change-detection and retry",
    "   logic above everything else: a bug that re-notifies on unchanged input is the",
    "   failure mode that actually hurts users here.",
    "2. `lib/main.dart` — Firebase/OneSignal/FCM setup, two `@pragma('vm:entry-point')`",
    "   top-level handlers that release-mode tree-shaking will remove if that pragma or",
    "   their top-level position is lost, and the write of every device's FCM token into",
    "   the `fcm_tokens` Firestore collection.",
    "3. `.gitignore` — the only guard keeping `lib/keys.dart`,",
    "   `android/app/google-services.json` and `key.jks` out of git history.",
    "4. `android/app/build.gradle` — release signing for the published app.",
    "5. `pubspec.yaml` — a new dependency ships inside that published app.",
    "",
    "Note for calibration: this repo has NO behavioural test coverage. `test/` holds one",
    "file and it is the unmodified `flutter create` counter template, which does not match",
    "this app and cannot pass. Nothing but `flutter analyze`, `dart format`, a codegen-drift",
    "check and this review stands behind the change. Do not assume coverage exists.",
    "",
    `task_id: ${taskId}`,
    `mode: ${mode}`,
    `tier: ${tier}`,
    `base: ${base}`,
    "",
    "## Brief",
    "",
    readOr(join(dir, "brief.md"), "<no brief.md>").trimEnd(),
    "",
    "## Plan",
    "",
    readOr(join(dir, "plan.md"), "<no plan.md>").trimEnd(),
    "",
    "## Changed files",
    "",
    ...reviewable.map((e) => `- ${e.status} ${e.path}${e.oldPath ? ` (from ${e.oldPath})` : ""}`),
  ];
  if (excluded.length > 0) {
    lines.push("", "## Excluded (machine-written)", "", ...excluded.map((e) => `- ${e.path}`));
  }
  lines.push("", "## Diff", "", "```diff", diff.trimEnd(), "```", "");
  return lines.join("\n");
}
