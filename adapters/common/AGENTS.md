## Purpose

This repository uses AI-assisted software engineering with a structured development workflow.

AI agents must treat repository-specific architecture, business rules, constraints, and documentation as authoritative project context.

## Engineering Priorities

Apply these priorities in order:

1. Correctness
2. Preservation of intended business behavior
3. Data integrity
4. Security
5. Testability
6. Maintainability
7. Performance
8. Simplicity
9. Minimal scope of change

Do not sacrifice a higher-priority concern for a lower-priority concern without explicitly identifying the tradeoff.

## Default Development Workflow

For non-trivial work, follow:

Understand → Investigate → Plan → Implement → Test → Review → Correct → Verify

Do not immediately modify code when investigation is required.

## Before Modifying Code

Before implementation:

- Understand the requirement.
- Inspect the relevant execution path.
- Search for existing implementations and patterns.
- Identify callers and downstream effects.
- Identify persistence and database effects.
- Identify relevant tests.
- Identify transaction and concurrency concerns when applicable.
- Inspect authoritative legacy behavior when modernization or parity is involved.

Do not infer behavior solely from filenames, class names, comments, or assumptions.

## Implementation

Prefer the smallest correct change.

Follow existing architecture and project conventions.

Do not:

- perform unrelated refactoring;
- introduce unnecessary abstractions;
- silently change business behavior;
- weaken validation;
- suppress meaningful errors;
- modify tests merely to hide implementation defects;
- introduce dependencies without a concrete need.

When requirements or behavior are ambiguous, report the ambiguity rather than inventing business rules.

## Testing

Tests must provide evidence of correct behavior.

Consider:

- expected behavior;
- invalid input;
- null or missing data;
- boundaries;
- duplicate execution;
- retries;
- partial failures;
- dependency failures;
- transaction rollback;
- concurrency;
- cancellation;
- authorization;
- legacy parity.

For bug fixes, prefer a regression test that demonstrates the original defect.

## Review

Review changes independently from implementation.

Prioritize:

- correctness;
- data integrity;
- security;
- business behavior;
- transaction safety;
- concurrency;
- architecture;
- tests;
- performance;
- maintainability.

Do not manufacture findings merely to appear thorough.

## Legacy Modernization

When replacing legacy functionality:

- identify the authoritative legacy implementation;
- trace legacy and modern implementations independently;
- compare observable behavior;
- compare persistence side effects;
- identify differences explicitly;
- identify unknown behavior explicitly;
- preserve required business behavior rather than legacy implementation structure.

Classify material behavior as:

- MATCH
- DIFFERENCE
- UNKNOWN

Do not assume newer behavior is correct simply because the implementation is newer.

## Verification

Before declaring implementation complete:

- build affected projects;
- run relevant tests;
- add or update tests for changed behavior;
- inspect the final diff;
- verify no unrelated changes were introduced;
- report unresolved risks and assumptions.

Implementation is not complete merely because it compiles.

## Human Control

AI agents may investigate, modify working files, build, and execute approved development tests.

AI agents must not perform external or destructive actions unless explicitly authorized.

Examples include:

- production changes;
- database schema changes;
- package upgrades unrelated to the task;
- pushing commits;
- merging pull requests;
- changing CI/CD infrastructure;
- deleting significant project resources.

Human approval remains the final acceptance step.
