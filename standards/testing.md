# Testing Standards

## Purpose

Testing must provide evidence that behavior is correct.

The objective is not maximum test count or coverage percentage. The objective is confidence in behavior.

## Testing Philosophy

Do not assume the implementation is correct.

Tests should be capable of exposing defects.

Prefer behavior-focused tests over implementation-detail tests.

Tests should remain valid when internal implementation changes but observable behavior remains the same.

## Test Selection

Evaluate relevant test categories:

- unit tests;
- integration tests;
- database tests;
- API tests;
- end-to-end tests;
- regression tests.

Not every change requires every test type.

Choose the lowest-cost level that provides meaningful confidence.

## Required Scenarios

Where applicable, evaluate:

- expected/happy path;
- invalid input;
- null or missing values;
- empty collections;
- boundary values;
- duplicate requests;
- repeated execution;
- partial failures;
- downstream failures;
- transaction rollback;
- retries;
- concurrency;
- cancellation;
- authorization;
- legacy compatibility.

## Regression Tests

Bug fixes should normally include a regression test that:

1. fails against the defective behavior;
2. passes after the correction.

When this is impractical, explain why.

## Legacy Modernization

When replacing legacy functionality, tests should verify observable parity.

Include important:

- branching behavior;
- defaults;
- null handling;
- calculations;
- persistence side effects;
- exception/error behavior;
- duplicate handling;
- ordering;
- external integration behavior.

## Test Quality

Avoid tests that simply reproduce the implementation.

Avoid assertions that do not meaningfully prove behavior.

Avoid excessive mocking when a lightweight real implementation provides better confidence.

Mocks should represent realistic dependency behavior.

## Test Isolation

Tests must not depend on:

- execution order;
- shared mutable state;
- production services;
- undocumented environment state.

Clean up data created during integration testing.

## Naming

Test names should communicate:

- scenario;
- condition;
- expected result.

Prefer names such as:

`ProcessImport_WhenRecordAlreadyExists_DoesNotCreateDuplicateSettlement`

over:

`TestProcessImport2`

## Test Failures

Never change expected test values merely to make failing tests pass without first determining whether:

- the implementation is wrong;
- the test is outdated;
- the requirement intentionally changed.

Report that determination.

## Completion

Report:

- tests added;
- tests modified;
- tests executed;
- failures;
- tests not run and why.
