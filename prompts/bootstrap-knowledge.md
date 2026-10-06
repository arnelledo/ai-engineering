# Bootstrap Project Knowledge

Bootstrap persistent project knowledge under `.ai/` for the current repository.

This is a knowledge-discovery task, not an implementation task.

Do not modify production source code.

## Objective

Build an initial, durable engineering knowledge base that helps future AI sessions understand this project without repeatedly rediscovering its architecture, behavior, persistence model, integrations, and legacy relationships.

Do not attempt to document every class or implementation detail.

Prefer concise knowledge that materially improves future investigation, implementation, testing, review, and legacy-parity work.

## Investigation

Systematically inspect the repository before writing project knowledge.

Use existing documentation, including README files and other project documentation, as initial evidence.

Verify important claims where possible against stronger repository evidence such as:

- source code;
- tests;
- configuration;
- dependency registration;
- persistence code;
- database mappings;
- integration code;
- message contracts;
- build/project configuration;
- legacy/reference implementations.

Do not treat existing documentation as automatically authoritative.

When documentation conflicts with executable evidence, identify the discrepancy.

## Knowledge to Discover

Determine, where supported by evidence:

- project purpose and responsibilities;
- architecture and major execution flows;
- projects and components and their responsibilities;
- important domain terminology;
- confirmed business behavior and business rules;
- database and persistence behavior;
- transaction boundaries;
- concurrency behavior;
- retry and idempotency behavior;
- external integrations and messaging;
- important configuration and operational constraints;
- legacy or modernization relationships;
- testing architecture;
- important known limitations or uncertainties.

## Knowledge Organization

Use the existing `.ai/` structure.

Store project-level context in:

- `.ai/project.md`
- `.ai/architecture.md`

Use domain-specific documents under:

- `.ai/business-rules/`
- `.ai/components/`
- `.ai/database/`
- `.ai/integrations/`
- `.ai/legacy/`

Use `.ai/decisions/` only when an engineering decision and its rationale can actually be established from available evidence.

Do not create decision records merely because the current implementation uses a particular design.

Do not create an active task document merely for the bootstrap operation.

Create additional domain-specific files only when they provide meaningful durable knowledge.

Avoid unnecessary fragmentation.

Avoid duplicating the same authoritative information across multiple knowledge files. Prefer links or references between documents when appropriate.

## Evidence Discipline

Clearly distinguish:

- confirmed repository-supported behavior;
- observed implementation behavior whose business intent is unknown;
- known uncertainties.

Do not convert implementation behavior into a business rule unless the evidence supports that interpretation.

Do not convert apparent legacy defects into intended business behavior.

Do not invent explanations for configuration differences, unusual implementation choices, or legacy behavior.

When intent cannot be established, document the observed behavior and explicitly mark the intent as unknown when the distinction is important.

## Existing Knowledge

Preserve useful existing `.ai/` knowledge.

Do not blindly regenerate or replace existing project knowledge.

When `.ai/` already contains substantive information:

1. inspect it;
2. verify relevant claims;
3. extend or correct it only when repository evidence supports the change.

Do not overwrite carefully established knowledge merely because the bootstrap analysis would phrase it differently.

## Validation

Before completion:

1. review all `.ai/` changes;
2. verify that claims are supported by repository evidence;
3. remove unnecessary duplication;
4. ensure speculation is not presented as fact;
5. verify no production source files were modified;
6. run `git diff --check` when Git is available.

## Completion Report

Report:

### Knowledge Files

Files created or updated.

### Important Knowledge Captured

Major durable knowledge established.

### Evidence

Important repository evidence used.

### Unknowns

Important questions that could not be established from repository evidence.

### Human Validation

Areas where domain-owner confirmation would materially improve the knowledge base.

### Verification

Confirm that production source code was not modified and report documentation validation performed.