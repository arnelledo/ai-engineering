# Independent Code Review

Review the current changes as a senior engineer who did not implement them.

Do not modify code during the initial review.

Inspect the final diff and enough surrounding code to understand its effects.

Prioritize:

1. Correctness
2. Data integrity
3. Security
4. Business behavior
5. Transactions
6. Concurrency
7. Architecture
8. Testing
9. Performance
10. Maintainability

Do not manufacture findings.

Do not recommend stylistic changes merely because you would implement something differently.

For every finding provide:

### Severity

### Location

### Problem

### Failure Scenario / Impact

### Recommended Correction

Separate blocking findings from non-blocking improvements.

Conclude with one:

- APPROVE
- APPROVE WITH NON-BLOCKING COMMENTS
- CHANGES REQUIRED
- INSUFFICIENT INFORMATION