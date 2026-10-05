# AI Engineering Instructions

This repository uses a structured AI-assisted engineering workflow.

Follow repository-specific architecture, business rules, testing conventions, and documented constraints.

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

## Development Workflow

For non-trivial work:

Understand → Investigate → Plan → Implement → Test → Review → Verify

Do not immediately modify code when the task requires investigation.

Before implementation:

- understand the requirement;
- trace the affected execution path;
- inspect callers and dependencies;
- search for existing implementations;
- identify persistence effects;
- inspect relevant tests;
- identify transaction and concurrency concerns where applicable.

Prefer the smallest correct change.

Do not perform unrelated refactoring.

Do not silently change existing business behavior.

Do not invent requirements when repository evidence is insufficient.

## Implementation

Follow existing architecture and project conventions.

Do not:

- introduce unnecessary abstractions;
- weaken validation;
- suppress meaningful errors;
- modify tests merely to hide defects;
- introduce unnecessary dependencies.

If implementation evidence contradicts an existing plan, identify the discrepancy before making broad changes.

## Testing

Tests should provide evidence of correct observable behavior.

For bug fixes, prefer regression tests reproducing the original defect.

Consider edge cases, invalid input, duplicate execution, partial failures, retries, transactions, concurrency, and cancellation where relevant.

## Review

Review the final diff before declaring completion.

Check for:

- unintended behavior changes;
- persistence changes;
- security issues;
- transaction problems;
- concurrency issues;
- missing tests;
- unrelated modifications.

## Legacy Modernization

When legacy functionality exists:

- identify the authoritative legacy implementation;
- trace legacy and modern behavior independently;
- compare observable behavior;
- compare persistence side effects;
- identify differences explicitly;
- identify unknown behavior explicitly.

Classify material behavior as:

- MATCH
- DIFFERENCE
- UNKNOWN

Preserve required business behavior rather than legacy implementation structure.

## Verification

Before completion:

- build affected projects;
- run relevant tests;
- add or update tests;
- inspect the final diff;
- report unresolved risks and assumptions.

Do not declare success when relevant verification failed.