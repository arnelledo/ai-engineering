# Development Standards

## Purpose

These standards define the default expectations for AI-assisted software development.

Project-specific architecture, business rules, technology constraints, and conventions always take precedence when explicitly documented.

## Engineering Priorities

Apply priorities in this order:

1. Correctness
2. Preservation of intended business behavior
3. Data integrity
4. Security
5. Testability
6. Maintainability
7. Performance
8. Simplicity
9. Minimal scope of change

Do not sacrifice a higher-priority concern for a lower-priority one without explicitly identifying the tradeoff.

## Before Modifying Code

Before implementation:

- Understand the requirement.
- Inspect the relevant execution path.
- Search for existing implementations and patterns.
- Identify callers and downstream effects.
- Identify persistence/database effects.
- Identify external integrations affected.
- Identify relevant existing tests.
- Identify concurrency or transaction concerns when applicable.
- For migrated behavior, inspect the authoritative legacy implementation.

Do not begin implementation based only on filenames, class names, or assumptions.

## Implementation Principles

Prefer the smallest correct change.

Follow existing project patterns unless there is a concrete reason not to.

Do not introduce new abstractions solely because they appear cleaner.

Do not perform unrelated refactoring while implementing a feature or fixing a bug.

Do not silently change existing business behavior.

Do not remove validations, error handling, logging, or safeguards merely to make an implementation work.

Do not duplicate behavior already implemented elsewhere.

Prefer explicit, readable code over clever code.

Avoid unnecessary dependencies.

Respect existing architectural boundaries.

## Existing Code

Treat existing code as evidence, not automatically as correct.

When behavior is unclear:

1. inspect callers;
2. inspect tests;
3. inspect persistence behavior;
4. inspect documentation;
5. inspect legacy/reference implementation when applicable.

If ambiguity remains, report it rather than inventing business behavior.

## Error Handling

Do not hide failures.

Preserve useful diagnostic information.

Do not catch exceptions unless:

- recovery is possible;
- additional useful context is added; or
- the architecture requires translating the exception.

Avoid empty catch blocks and broad exception handling without justification.

## Logging

Logging should help diagnose real production behavior.

Do not log secrets or sensitive information.

Avoid excessive informational logging inside hot loops.

When useful, include identifiers that allow execution paths to be correlated.

## Database and Persistence

Before modifying persistence behavior, identify:

- tables/entities affected;
- reads;
- inserts;
- updates;
- deletes;
- transaction boundaries;
- retries;
- idempotency concerns;
- triggers or database-side behavior when relevant.

Never assume database schema changes are acceptable.

Do not create migrations or alter schemas unless explicitly required.

## Concurrency

When code may execute concurrently, evaluate:

- shared state;
- duplicate processing;
- race conditions;
- transaction isolation;
- idempotency;
- ordering requirements;
- retry behavior.

Do not introduce parallelism without evaluating thread safety and data consistency.

## Dependencies

Do not upgrade packages or frameworks as part of unrelated work.

Do not introduce a dependency when equivalent project functionality already exists.

## Generated Code

Do not manually modify generated code unless the project explicitly requires it.

Prefer changing the source or generator configuration.

## Completion

Implementation is not complete merely because it compiles.

Before declaring completion:

- build affected projects;
- run relevant tests;
- add or update tests for changed behavior;
- inspect the final diff;
- verify no unrelated files changed;
- identify unresolved risks or assumptions.
