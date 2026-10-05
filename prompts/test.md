# Test

Test the requested implementation adversarially.

Do not assume the implementation is correct.

Inspect relevant persistent project knowledge before testing non-trivial behavior.

Consider where applicable:

- happy path;
- invalid input;
- null and missing values;
- empty values;
- boundary conditions;
- duplicate input;
- repeated execution;
- retries;
- partial failures;
- dependency failures;
- database side effects;
- transaction rollback;
- concurrency;
- cancellation;
- ordering;
- authorization;
- legacy parity.

For a bug fix, create or identify a regression test that would fail without the correction when practical.

Do not weaken existing assertions merely to make tests pass.

Report:

1. Behaviors tested
2. Tests added or modified
3. Edge cases covered
4. Defects discovered
5. Coverage gaps
6. Test execution results
7. Project knowledge impact