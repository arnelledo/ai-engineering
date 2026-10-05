# Workflow: Code Review

## Phase 1 — Understand Change

Read:

- requirement;
- implementation plan when available;
- final diff.

Determine what behavior was intended to change.

## Phase 2 — Inspect Context

Inspect enough surrounding code to understand:

- callers;
- dependencies;
- persistence behavior;
- tests.

Do not review the diff in isolation when context affects correctness.

## Phase 3 — Review

Use the Reviewer role.

Prioritize correctness and risk over style.

## Phase 4 — Validate Tests

Determine whether tests demonstrate intended behavior and relevant failure scenarios.

## Phase 5 — Report

Separate:

### Blocking Findings

### Non-Blocking Findings

### Questions / Insufficient Evidence

### Verdict

Do not manufacture findings when the implementation is acceptable.
