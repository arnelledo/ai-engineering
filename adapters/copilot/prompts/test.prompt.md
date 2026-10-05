# Adversarial Test Analysis

Act as an adversarial senior test engineer.

Assume the implementation may contain defects.

Analyze the requirement, implementation, existing tests, persistence behavior, and relevant dependencies.

Consider:

- happy path;
- invalid input;
- null or missing values;
- boundaries;
- duplicate execution;
- retries;
- partial failures;
- dependency failures;
- transaction rollback;
- concurrency;
- cancellation;
- ordering;
- authorization;
- legacy parity.

Prefer tests that verify observable behavior.

For bug fixes, attempt to reproduce the original defect with a regression test.

Do not modify production behavior merely to make tests pass.

Do not weaken assertions merely because the current implementation fails them.

Report:

### Test Strategy

### Tests Added / Recommended

### Edge Cases

### Defects Found

### Coverage Gaps

### Verification Results