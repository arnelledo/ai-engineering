# Workflow: Legacy Modernization

## Phase 0 — Planned Task

Apply this phase only when the request names a planned task (`T-NN-NN`). Otherwise, go to Phase 1.

Read the task, its requirements, `SPEC.md`, its test scenarios, the accepted ADRs under `.ai/decisions/`, and `.ai/plan/sources.md`. The sources cited by the requirements identify the source of truth.

If its feature is not `READY`, stop and report what is missing. Do not implement.

If an earlier task it depends on is not `DONE`, stop and report it.

A `CHANGE` requirement is an approved difference. Any other difference is not approved.

The Tester names tests with the requirement they verify when the language allows it.

If a gap appears or the size limit is exceeded in any phase, stop as defined in the Project Planning Standards.

## Phase 1 — Identify Source of Truth

Determine the authoritative legacy implementation.

Identify the modern implementation being compared.

## Phase 2 — Legacy Analysis

Use the Legacy Parity Analyst.

Document observable legacy behavior independently.

## Phase 3 — Modern Analysis

Document current modern behavior independently.

## Phase 4 — Parity Comparison

Classify behaviors as:

- MATCH
- DIFFERENCE
- UNKNOWN

Identify blocking differences.

## Phase 5 — Plan

Use the Planner role.

Create the minimum implementation plan required to achieve intended parity.

Do not mechanically port obsolete architecture.

Preserve behavior, not implementation structure.

## Phase 6 — Implement

Use the Developer role.

## Phase 7 — Parity Tests

Use the Tester role.

Add tests for:

- important business rules;
- identified differences;
- edge cases;
- persistence effects;
- failure behavior.

## Phase 8 — Independent Review

Use the Reviewer role.

Review with particular attention to:

- undocumented behavior changes;
- data differences;
- transaction changes;
- duplicate behavior;
- concurrency;
- missing legacy branches.

## Completion

Produce an overall parity assessment.

Any remaining DIFFERENCE or UNKNOWN item must be explicitly documented.

For a planned task, update its status in `TASKS.md` in the same change, prepare the pull request description defined in the Project Planning Standards, and stop.
