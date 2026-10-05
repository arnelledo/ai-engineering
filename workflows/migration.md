# Workflow: Legacy Modernization

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
