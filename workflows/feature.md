# Workflow: Feature Development

## Phase 0 — Planned Task

Apply this phase only when the request names a planned task (`T-NN-NN`). Otherwise, go to Phase 1.

Read the task, its requirements, `SPEC.md`, its test scenarios, and the accepted ADRs under `.ai/decisions/`.

If its feature is not `READY`, stop and report what is missing. Do not implement.

If an earlier task it depends on is not `DONE`, stop and report it.

The Tester names tests with the requirement they verify when the language allows it.

If a gap appears or the size limit is exceeded in any phase, stop as defined in the Project Planning Standards.

## Phase 1 — Understand

Read:

- requirement;
- project instructions;
- relevant documentation.

Do not modify code.

## Phase 2 — Investigate

Use the Planner role.

Identify:

- execution path;
- impacted components;
- persistence effects;
- risks;
- tests.

Produce an implementation plan.

## Phase 3 — Implement

Use the Developer role.

Implement the approved plan using the smallest correct change.

## Phase 4 — Test

Use the Tester role.

Add or update tests.

Actively search for failure scenarios.

## Phase 5 — Review

Use the Reviewer role.

Review the final diff independently.

## Phase 6 — Correct

Resolve blocking findings.

Run affected verification again.

## Phase 7 — Complete

Report:

- behavior implemented;
- changed files;
- tests;
- verification;
- unresolved risks.

Do not declare completion with unresolved blocking failures.

For a planned task, update its status in `TASKS.md` in the same change, prepare the pull request description defined in the Project Planning Standards, and stop.
