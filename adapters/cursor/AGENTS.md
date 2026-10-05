# AI Engineering Instructions

Follow repository-specific architecture, business rules, testing conventions, and documented constraints.

## Priorities

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

Do not immediately modify code when investigation is required.

Before implementation:

- understand the affected execution path;
- inspect callers and dependencies;
- search for existing implementations;
- identify persistence effects;
- inspect relevant tests;
- identify transaction and concurrency concerns when applicable.

Prefer the smallest correct change.

Do not:

- perform unrelated refactoring;
- silently change business behavior;
- weaken tests to make code pass;
- invent requirements when evidence is missing.

## Legacy Modernization

When legacy functionality exists, compare observable legacy and modern behavior.

Classify material behavior as:

- MATCH
- DIFFERENCE
- UNKNOWN

Preserve required business behavior rather than legacy implementation structure.

## Completion

Before completion:

- build affected projects;
- run relevant tests;
- inspect the final diff;
- verify no unrelated changes were introduced;
- report unresolved risks.