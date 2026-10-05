
# AI Engineering Instructions

Follow the repository's project-specific architecture, business rules, testing conventions, and documented constraints.

## Priorities

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

## Workflow

For non-trivial development:

Understand → Investigate → Plan → Implement → Test → Review → Verify

Do not immediately implement a change that requires investigation.

Before modifying code:

- understand the affected execution path;
- inspect callers and dependencies;
- search for existing implementations;
- identify persistence effects;
- inspect relevant tests;
- identify transaction and concurrency concerns when applicable.

Prefer the smallest correct change.

Do not perform unrelated refactoring.

Do not silently change existing business behavior.

Do not invent requirements when repository evidence is insufficient.

## Testing

Add or update tests for changed behavior.

For bug fixes, prefer a regression test reproducing the defect.

Tests should verify observable behavior rather than merely reproduce implementation details.

## Legacy Modernization

When replacing legacy functionality:

- identify the authoritative legacy implementation;
- compare observable behavior;
- compare persistence side effects;
- identify differences and unknown behavior explicitly;
- preserve required business behavior rather than implementation structure.

## Verification

Before declaring work complete:

- build affected projects;
- run relevant tests;
- inspect the final diff;
- verify no unrelated modifications were introduced;
- report unresolved risks or assumptions.