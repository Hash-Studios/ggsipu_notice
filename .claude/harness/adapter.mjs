// ggsipu_notice's v2 adapter — repo-specific answers only (adapter API 1). The global
// core (task lifecycle, verify runner, review execution, completion gate, worktrees,
// locks) is never duplicated here; see ~/.claude/harness/source/docs/ARCHITECTURE.md.
//
// classifyChanges/deriveRisk delegate, verbatim, to this repo's own file classifier and
// review policy (adapter/classify.mjs, adapter/reviewpolicy.mjs — moved unchanged from
// the v1 tool/harness/lib/). buildVerificationPlan delegates to the v1 verify shim's own
// CHECKS/TIER_CHECKS table (adapter/checks.mjs, moved unchanged). reviewPreamble and
// getGeneratedFileRules are left to the config-driven defaults (config.review.preamble /
// config.review.generated).

import { classifyChanges as v1ClassifyChanges } from "./adapter/classify.mjs";
import { requiredReviewMode } from "./adapter/reviewpolicy.mjs";
import { CHECKS, TIER_CHECKS } from "./adapter/checks.mjs";

export const adapterApi = 1;

export function classifyChanges(ctx) {
  const { requiredTier, reasons } = v1ClassifyChanges(ctx.changedPaths);
  return { requiredTier, reasons };
}

export function deriveRisk(ctx) {
  const { mode, reasons } = requiredReviewMode(ctx.changedPaths);
  return { mode, reasons };
}

export function buildVerificationPlan(ctx) {
  const names = TIER_CHECKS[ctx.tier] ?? [];
  return names.map((name) => {
    const c = CHECKS[name];
    if (!c) throw new Error(`adapter/checks.mjs: TIER_CHECKS.${ctx.tier} names unknown check "${name}"`);
    const base = { name, description: c.description, required: c.required !== false, available: c.available };
    return c.cmd ? { ...base, cmd: c.cmd } : { ...base, run: c.run };
  });
}
