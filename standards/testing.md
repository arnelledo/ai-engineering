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
- empty values and empty collections;
- minimum and maximum boundary values;
- duplicate input and duplicate requests;
- repeated execution;
- retries;
- partial failures;
- downstream and database failures;
- transaction rollback;
- concurrency;
- cancellation;
- ordering;
- authorization;
- legacy compatibility;
- unexpected but valid input combinations.

## Regression Tests

Bug fixes should normally include a regression test that:

1. fails against the defective behavior;
2. passes after the correction.

The test should prove the behavior that was defective, not merely exercise the modified method.

When this is impractical, explain why.

## Persistence Testing

When persistence is involved, verify where applicable:

- correct records are created;
- correct records are updated;
- incorrect records are not created;
- rollback occurs when required;
- duplicates are handled correctly;
- repeated execution produces expected results;
- transaction boundaries behave correctly;
- side effects match business behavior.

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

Do not:

- weaken existing assertions to make tests pass;
- blindly update expected values;
- create tests that merely repeat implementation logic;
- use assertions that do not meaningfully prove behavior;
- excessively mock behavior that should be verified;
- treat compilation as testing.

Prefer a lightweight real implementation over a mock when it provides better confidence.

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
