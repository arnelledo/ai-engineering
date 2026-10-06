# Engineering Process and Human Control

## Engineering Workflow

For non-trivial work:

1. Understand the requirement.
2. Inspect relevant persistent project knowledge.
3. Investigate the existing implementation.
4. Identify root cause or expected design.
5. Plan the smallest correct change.
6. Implement.
7. Test adversarially.
8. Review independently.
9. Correct blocking findings.
10. Build and run relevant tests.
11. Inspect the final diff.
12. Identify any durable project-knowledge updates.

Do not skip investigation merely to reach implementation faster.

## Human Control

Do not perform consequential external or destructive actions without explicit authorization.

This includes:

- production deployment;
- destructive database operations;
- pushing commits;
- merging pull requests;
- production infrastructure changes;
- unrelated dependency upgrades;
- unrelated CI/CD modifications.

Compilation alone is not sufficient evidence that a task is complete.
