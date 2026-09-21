// ggsipu_notice's completion gate: the IO wiring around the runtime's pure `evaluateStop`.
//
// The generic runtime ships `evaluateStop` (the decision) but NOT this wrapper, because
// the two values it needs — "what tier do these changed files require" and "what review
// mode do they require" — can only be answered by a repo's own classifier and review
// policy (~/.claude/harness/runtime/README.md, "Left out"). This file supplies them from
// lib/classify.mjs and lib/reviewpolicy.mjs, reads the artifacts off disk, and hands the
// result to evaluateStop.
//
// Fails CLOSED: an unreadable state file, an unreadable artifact, or a thrown error is
// never "fine to finish".

import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

import { classifyChanges, POLICY_FILES, FINGERPRINT_EXCLUDE_PREFIXES } from "./classify.mjs";
import { requiredReviewMode, reviewPolicyFingerprint } from "./reviewpolicy.mjs";
import { buildPacket, fingerprintOf, reviewInputContentFingerprint } from "./reviewpacket.mjs";

const RUNTIME_LIB = process.env.CLAUDE_HARNESS_RUNTIME || join(homedir(), ".claude", "harness", "runtime", "lib");

export const VERIFY_CMD = "tool/harness/verify";
export const REVIEW_CMD = "tool/harness/review";
export const VERIFY_SCHEMA_VERSION = 3;

async function runtime(name) {
  const path = join(RUNTIME_LIB, name);
  if (!existsSync(path)) throw new Error(`harness runtime module not found: ${path} (set CLAUDE_HARNESS_RUNTIME or reinstall the harness)`);
  return import(pathToFileURL(path).href);
}

function fileFingerprint(path) {
  try {
    return `sha256:${createHash("sha256").update(readFileSync(path)).digest("hex")}`;
  } catch {
    return undefined;
  }
}

function readTextOr(path, fallback) {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return fallback;
  }
}

function maxOf(a, b) {
  const rank = { none: 0, standard: 1, adversarial: 2 };
  return (rank[a] ?? 0) >= (rank[b] ?? 0) ? a : b;
}

/**
 * evaluateGate({ cwd }) -> { decision, reason_code, message?, context }
 *
 * `context` is diagnostic only — never an input to the decision.
 */
export async function evaluateGate({ cwd }) {
  const { readActiveTaskId, readState, taskDir } = await runtime("taskstate.mjs");
  const { computeDiff } = await runtime("diff.mjs");
  const { workspaceFingerprint, policyFingerprint } = await runtime("fingerprint.mjs");
  const { evaluateStop, computeScopeStatus, readJsonArtifact } = await runtime("gate.mjs");

  const taskId = readActiveTaskId({ cwd });
  if (taskId === null) {
    // No active harness task. Ordinary answers, questions and planning are never gated.
    return { decision: "allow", reason_code: "NO_ACTIVE_TASK", context: {} };
  }

  const stateRead = readState({ cwd, taskId });
  if (!stateRead.ok) {
    return {
      decision: "block",
      reason_code: "MALFORMED_STATE",
      message: `Completion blocked: task "${taskId}" is active but its state.json is ${stateRead.error}. Fix it with tool/harness/task, or clear .claude/tasks/.active.`,
      context: { taskId },
    };
  }
  const state = stateRead.state;

  const diff = computeDiff({ cwd, baseRefArg: undefined, filesOverride: undefined });
  const changedEntries = diff.changedFiles ?? [];
  const changedPaths = changedEntries.map((e) => e.path);

  const { requiredTier: classifierRequiredTier } = classifyChanges(changedPaths);
  const { mode: policyReviewMode } = requiredReviewMode(changedPaths);
  // The task may demand a stricter review than policy does; it may never demand a
  // weaker one.
  const requiredMode = state.review.required ? maxOf(policyReviewMode, state.review.mode) : policyReviewMode;

  const dir = taskDir({ cwd, taskId });
  const verify = readJsonArtifact({ cwd, taskId, name: "verify.json", taskDirFn: taskDir });
  const review = readJsonArtifact({ cwd, taskId, name: "review.json", taskDirFn: taskDir });
  const adjudicationRaw = readJsonArtifact({ cwd, taskId, name: "adjudication.json", taskDirFn: taskDir });

  const defaultWorkspaceFp = workspaceFingerprint({ cwd, changedFiles: changedEntries, excludePrefixes: FINGERPRINT_EXCLUDE_PREFIXES });
  const policyFp = policyFingerprint({ cwd, policyFiles: POLICY_FILES });
  const scopeStatus = verify && typeof verify === "object" ? computeScopeStatus({ cwd, verify, defaultWorkspaceFp }) : undefined;

  const packetText = buildPacket({
    cwd,
    taskId,
    base: diff.base,
    changedEntries,
    mode: requiredMode,
    tier: state.required_tier,
  });

  const decision = evaluateStop({
    cwd,
    taskId,
    state,
    verify,
    classifierRequiredTier,
    policyFp,
    workspaceFp: defaultWorkspaceFp,
    scopeStatus,
    requiredReviewMode: requiredMode,
    review,
    verifyArtifactFp: fileFingerprint(join(dir, "verify.json")),
    reviewPolicyFp: reviewPolicyFingerprint({ cwd }),
    reviewPacketFp: fingerprintOf(packetText),
    reviewInputContentFp: reviewInputContentFingerprint({ cwd, taskId }),
    reviewInputContentStoredFp: review && typeof review === "object" ? review.review_input_content_fingerprint : undefined,
    currentCommitSha: diff.head,
    reviewJsonFp: fileFingerprint(join(dir, "review.json")),
    adjudicationRaw,
    decisionsMdText: readTextOr(join(dir, "decisions.md"), ""),
    verifySchemaVersion: VERIFY_SCHEMA_VERSION,
    verifyCmd: VERIFY_CMD,
    reviewCmd: REVIEW_CMD,
  });

  return {
    ...decision,
    context: {
      taskId,
      state: state.state,
      declared_tier: state.required_tier,
      classifier_required_tier: classifierRequiredTier,
      required_review_mode: requiredMode,
      changed_files: changedPaths.length,
    },
  };
}
