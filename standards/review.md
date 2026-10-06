# Code Review Standards

## Purpose

Code review exists to identify meaningful risk before changes are accepted.

Do not manufacture findings to appear thorough.

Do not recommend changes solely because another implementation style is preferred.

Do not report purely stylistic preferences unless they create meaningful engineering risk or are specifically requested.

## Review Order

Review in this order:

1. correctness;
2. data integrity;
3. security;
4. business behavior;
5. transactions and concurrency;
6. architecture;
7. testing;
8. performance;
9. maintainability.

## Review Method

Review the change in context.

Inspect where relevant:

- requirement;
- implementation plan;
- final diff;
- surrounding code;
- callers;
- tests;
- persistence behavior;
- transaction handling;
- concurrency;
- authorization;
- error paths;
- external integrations;
- relevant legacy behavior;
- relevant engineering decisions.

Review the final diff, not only individual files.

Do not review the diff in isolation when context affects correctness.

## Special Attention

Look specifically for:

- unsupported assumptions;
- null handling defects;
- missing validation;
- duplicate processing;
- race conditions;
- transaction mistakes;
- partial-failure behavior;
- persistence inconsistencies;
- authorization gaps;
- exception handling defects;
- inadequate tests;
- unrelated scope expansion;
- behavior differences from authoritative legacy implementations.

## Severity

Classify every finding using exactly one severity.

Do not inflate severity.

### CRITICAL

Likely catastrophic impact, such as:

- data corruption or loss;
- a serious, exploitable security vulnerability;
- incorrect financial behavior;
- destructive production behavior;
- major race conditions or severe transaction failures with data consequences.

### HIGH

Likely production defect or significant business impact, such as:

- incorrect business logic;
- significant regression risk;
- missing authorization;
- broken transaction behavior;
- incorrect persistence behavior;
- architecture violations with real consequences;
- important legacy parity differences.

### MEDIUM

Meaningful defect or maintainability problem with realistic impact but lower severity or probability, such as:

- insufficient error handling;
- meaningful performance problems;
- missing important tests;
- maintainability problems likely to cause defects.

### LOW

Minor engineering concern with limited impact, such as:

- naming;
- readability;
- minor duplication;
- style inconsistencies.

Report LOW cosmetic issues only when specifically requested.

## Required Finding Format

Every finding must include:

**Severity**

CRITICAL, HIGH, MEDIUM, or LOW.

**Location**

File and relevant code location.

**Problem**

What is wrong.

**Failure Scenario / Impact**

A realistic scenario where the problem matters.

**Recommended Correction**

How it should be addressed.

## Evidence

Do not present speculation as a defect.

If evidence is insufficient, classify the observation as a question or risk rather than a finding.

## Scope

Identify unrelated changes.

Flag unnecessary refactoring when it increases review or regression risk.

## Tests

Determine whether tests:

- prove the requested behavior;
- include regression coverage where appropriate;
- cover meaningful edge cases and negative cases;
- verify failure behavior;
- validate persistence effects where relevant;
- cover duplicate, retry, and concurrency behavior when applicable;
- avoid weak assertions;
- avoid blindly reproducing implementation logic.

## Review Outcome

Conclude with exactly one verdict:

- APPROVE
- APPROVE WITH NON-BLOCKING COMMENTS
- CHANGES REQUIRED
- INSUFFICIENT INFORMATION

Explain blocking findings separately from optional improvements.
