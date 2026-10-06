# AI Engineering Framework

A reusable, harness-independent framework for AI-assisted software engineering.

The objective is to improve engineering quality while reducing implementation time by giving AI coding tools a disciplined engineering process rather than treating them as autocomplete.

## Core Model

The framework separates three different concerns:

```text
Engineering Framework
        +
Persistent Project Knowledge
        +
Active Task Context
```

### Engineering Framework

Defines how AI should work.

Stored in this private framework repository:

```text
standards/
agents/
workflows/
```

### Persistent Project Knowledge

Defines how a specific application works.

Stored with the application repository:

```text
.ai/
```

### Active Task Context

Preserves investigation and implementation context across sessions and specialized agents.

Stored with the application repository:

```text
.ai/tasks/
```

## Engineering Workflow

For non-trivial work:

```text
Understand
    ↓
Investigate
    ↓
Plan
    ↓
Implement
    ↓
Test
    ↓
Review
    ↓
Correct
    ↓
Verify
    ↓
Human Approval
```

Legacy modernization adds explicit parity analysis before implementation.

## Repository Structure

```text
ai-engineering/
├── README.md
├── standards/
│   ├── development.md
│   ├── testing.md
│   ├── review.md
│   ├── security.md
│   └── legacy-parity.md
├── agents/
│   ├── orchestrator.md
│   ├── planner.md
│   ├── developer.md
│   ├── tester.md
│   ├── reviewer.md
│   └── legacy-parity.md
├── workflows/
│   ├── feature.md
│   ├── bug-fix.md
│   ├── migration.md
│   └── code-review.md
├── prompts/
│   ├── investigate.md
│   ├── test.md
│   └── parity.md
├── adapters/
│   └── README.md
└── scripts/
    └── install.ps1
```

## Source of Truth

The canonical engineering definitions live in:

- `standards/`
- `agents/`
- `workflows/`
- `prompts/`

These files are the source of truth.

Harness-specific files such as GitHub Copilot agents and prompts are generated from these canonical definitions.

The deployment flow is:

Canonical Framework → `install.ps1` → Application Repository

The application repository receives:

- `.github/copilot-instructions.md`
- `.github/agents/`
- `.github/prompts/`

Project-specific knowledge lives separately under `.ai/`.

Do not manually maintain multiple copies of the same engineering instructions when they can be generated from a canonical source.

## Standards

`standards/` defines general engineering expectations.

Examples:

- implementation discipline;
- testing quality;
- code review;
- security;
- legacy parity.

Standards should remain application-independent.

## Agents

`agents/` contains canonical specialized engineering roles.

### Orchestrator

Coordinates non-trivial work and selects the appropriate workflow.

### Planner

Investigates requirements, execution flow, root cause, risks, and implementation strategy.

### Developer

Implements the smallest correct change.

### Tester

Performs adversarial verification.

### Reviewer

Independently evaluates correctness, risk, business behavior, architecture, security, and test quality.

### Legacy Parity Analyst

Compares modern behavior against authoritative legacy behavior.

## Workflows

`workflows/` defines repeatable engineering processes.

### Feature

Used for non-trivial feature development.

### Bug Fix

Requires root-cause investigation and regression verification.

### Migration

Used when legacy behavior must be preserved or intentionally changed.

### Code Review

Used for independent review without initial implementation changes.

## Specialist Prompts

The `prompts/` directory contains reusable specialist operations that are not complete engineering workflows.

### Investigate

Canonical source:

`prompts/investigate.md`

Generated as `/investigate` for GitHub Copilot and executed using the Planner agent.

Its purpose is to investigate a problem without modifying production code.

### Test

Canonical source:

`prompts/test.md`

Generated as `/test` for GitHub Copilot and executed using the Tester agent.

Its purpose is to test an implementation adversarially.

### Parity

Canonical source:

`prompts/parity.md`

Generated as `/parity` for GitHub Copilot and executed using the Legacy Parity agent.

Its purpose is to compare modern behavior against an authoritative legacy implementation.

### Bootstrap Project Knowledge

`/bootstrap-knowledge` performs the initial knowledge-discovery pass for a repository.

It investigates repository documentation, source code, tests, configuration, persistence, integrations, and legacy/reference implementations and populates the appropriate `.ai/` project-knowledge documents.

The bootstrap process is evidence-driven. It must distinguish confirmed behavior from implementation observations and unknown business intent.

Bootstrap is intended primarily for initial project onboarding. Persistent project knowledge should normally evolve incrementally through subsequent engineering work rather than being repeatedly regenerated.

### Review

There is intentionally no `prompts/review.md`.

The canonical source for `/review` is:

`workflows/code-review.md`

This prevents duplicate review instructions and keeps a single source of truth.

## Persistent Project Knowledge

Application-specific engineering knowledge belongs inside the application repository under:

```text
.ai/
├── README.md
├── project.md
├── architecture.md
├── business-rules/
├── components/
├── database/
├── integrations/
├── legacy/
├── decisions/
└── tasks/
```

This knowledge should not be stored in the generic framework repository.

Examples of application-specific information include:

- business rules;
- database tables;
- service architecture;
- integration behavior;
- legacy implementation details;
- accepted engineering decisions;
- project terminology.

## Project Knowledge Principles

Project documentation provides useful engineering context but is not automatically authoritative.

When documentation conflicts with:

- source code;
- executable tests;
- database constraints;
- integration contracts;
- observed runtime behavior;

the discrepancy should be investigated and reported.

Do not silently choose whichever source is more convenient.

## Durable Knowledge

Examples of durable project knowledge include:

- confirmed business rules;
- architectural constraints;
- persistence rules;
- integration contracts;
- intentional legacy differences;
- accepted engineering decisions;
- concurrency requirements.

Durable knowledge belongs in the appropriate `.ai/` document.

## Active Task Context

Significant work may maintain a document under:

```text
.ai/tasks/
```

Task documents preserve working context across:

- days;
- AI conversations;
- agents;
- investigation;
- implementation;
- testing;
- review.

Task documents may contain:

- requirement;
- confirmed evidence;
- hypotheses;
- root cause;
- plan;
- implementation status;
- test results;
- review findings;
- unresolved questions;
- next steps.

Task documents are working context and are not automatically authoritative business documentation.

## Knowledge Maintenance

At the end of significant work, determine whether durable project knowledge was discovered or changed.

Confirmed durable knowledge should be added to the appropriate `.ai/` document.

Do not promote:

- speculation;
- temporary debugging observations;
- failed hypotheses;
- incomplete conclusions

into permanent project documentation.

## Harness Adapters

The framework is designed to remain independent from a specific AI product.

Harness-specific integration belongs under:

`adapters/`

Adapters must not contain independent copies of canonical engineering instructions.

The canonical source of truth remains:

- `standards/`
- `agents/`
- `workflows/`
- `prompts/`

Adapters should contain only harness-specific metadata, templates, transformations, or deployment logic required to translate the canonical framework into a format understood by a particular AI harness.

### GitHub Copilot

GitHub Copilot is currently the primary supported harness.

Copilot deployment is currently implemented directly by:

`scripts/install.ps1`

The installer generates Copilot-native files in the target application repository from the canonical framework definitions.

### Future Harnesses

Additional adapters may later be implemented for harnesses such as Claude or Cursor.

Those adapters should consume the canonical framework rather than maintain independent copies of engineering instructions.

## GitHub Copilot Deployment

The installer generates Copilot-native files inside an application repository.

Example:

```text
.github/
├── copilot-instructions.md
├── agents/
│   ├── orchestrator.agent.md
│   ├── planner.agent.md
│   ├── developer.agent.md
│   ├── tester.agent.md
│   ├── reviewer.agent.md
│   └── legacy-parity.agent.md
│
└── prompts/
    ├── feature.prompt.md
    ├── bug-fix.prompt.md
    ├── migration.prompt.md
    ├── investigate.prompt.md
    ├── test.prompt.md
    ├── review.prompt.md
    └── parity.prompt.md
```

## Installation and Framework Updates

The framework uses a single deployment script:

`scripts/install.ps1`

A separate `update.ps1` is intentionally not required.

The same installer is used for both initial installation and future framework synchronization.

### First Installation

Preview the installation first:

    .\scripts\install.ps1 `
        -TargetRepo "C:\path\to\application" `
        -DryRun

Then install:

    .\scripts\install.ps1 `
        -TargetRepo "C:\path\to\application"

Do not use `-Force` for a normal first installation.

### Updating an Application After Framework Changes

When the canonical framework changes, for example:

- an agent changes;
- a standard changes;
- a workflow changes;
- a specialist prompt changes;
- generation logic changes;

preview the update with:

    .\scripts\install.ps1 `
        -TargetRepo "C:\path\to\application" `
        -DryRun `
        -Force

After reviewing the intended changes, apply them with:

    .\scripts\install.ps1 `
        -TargetRepo "C:\path\to\application" `
        -Force

Therefore the normal update workflow is:

Framework change → `-DryRun -Force` → Review → `-Force` → Review Git diff

### What `-Force` Means

`-Force` authorizes the installer to replace framework-generated files that already exist in the target repository.

Framework-owned files include:

- `.github/copilot-instructions.md`
- `.github/agents/*`
- `.github/prompts/*`
- `.ai/framework-manifest.json`

Project-specific knowledge is protected from `-Force`.

The application owns:

- `.ai/README.md`
- `.ai/project.md`
- `.ai/architecture.md`
- `.ai/business-rules/*`
- `.ai/components/*`
- `.ai/database/*`
- `.ai/integrations/*`
- `.ai/legacy/*`
- `.ai/decisions/*`
- `.ai/tasks/*`

The installer must not overwrite these project-owned knowledge files merely because `-Force` was supplied.

### When Not to Run the Installer

Changes made only to application-specific `.ai/` knowledge do not require running `install.ps1`.

For example, changing:

`.ai/business-rules/shipping-import.md`

or:

`.ai/tasks/settlements-not-created.md`

does not require reinstalling the framework.

Run `install.ps1` when deploying or synchronizing changes from the shared AI Engineering Framework.

## Security

Do not store secrets in framework or project-knowledge documentation.

Examples include:

- passwords;
- API keys;
- access tokens;
- private certificates;
- production credentials;
- secret connection strings.

## Human Control

AI may assist with:

- repository investigation;
- planning;
- implementation;
- builds;
- tests;
- code review;
- parity analysis.

Consequential operations require explicit human authorization.

Examples include:

- production deployment;
- destructive database operations;
- pushing or merging changes;
- production infrastructure changes;
- unrelated dependency upgrades;
- consequential CI/CD modifications.

## Design Principle

The framework should make AI behave like a disciplined engineering team.

Correctness and evidence are more important than the amount of generated code.