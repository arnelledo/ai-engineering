# Project Knowledge Standards

## Persistent Project Knowledge

Project-specific engineering knowledge is maintained under `.ai/`.

For non-trivial work, inspect relevant project knowledge before planning or modifying code.

Start with:

- `.ai/project.md`
- `.ai/architecture.md`

Then inspect only the knowledge relevant to the task:

- business behavior -> `.ai/business-rules/`
- component behavior -> `.ai/components/`
- persistence behavior -> `.ai/database/`
- external systems -> `.ai/integrations/`
- legacy behavior -> `.ai/legacy/`
- previous engineering decisions -> `.ai/decisions/`
- active or related work -> `.ai/tasks/`
- planned features, requirements, and open questions -> `.ai/plan/`

Do not load unrelated project knowledge unnecessarily.

## Evidence

Project documentation provides context but may become outdated.

Source code, executable tests, database constraints, integration contracts, and observed behavior may provide stronger evidence.

When documentation materially conflicts with executable evidence:

1. identify the discrepancy;
2. investigate which behavior is authoritative;
3. report the discrepancy;
4. do not silently choose an interpretation.

Do not invent project-specific behavior when evidence is unavailable.

## Active Task Continuity

For significant work spanning multiple phases or sessions, use an active task document under `.ai/tasks/`.

Task documents may preserve:

- requirement or problem;
- relevant project knowledge;
- confirmed evidence;
- hypotheses;
- root cause;
- relevant files;
- implementation plan;
- implementation status;
- tests;
- review findings;
- unresolved questions;
- next steps;
- durable knowledge candidates.

Clearly distinguish confirmed evidence from hypotheses.

Task documents are working context and are not automatically authoritative business documentation.

## Knowledge Maintenance

At the completion of significant work, determine whether durable project knowledge was discovered or changed.

Examples include:

- confirmed business rules;
- persistence constraints;
- integration behavior;
- architectural decisions;
- intentional legacy differences;
- concurrency requirements;
- important operational constraints.

Update durable project knowledge only when sufficiently supported by evidence.

Do not convert debugging hypotheses, temporary observations, or speculation into permanent project documentation.
