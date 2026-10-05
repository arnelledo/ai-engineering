# AI Engineering Framework

A reusable, harness-independent framework for AI-assisted software engineering.

The framework defines common engineering standards, specialized AI roles, repeatable development workflows, and adapters for AI development tools.

The objective is not to maximize AI-generated code.

The objective is to improve engineering quality while reducing the time required to investigate, implement, test, and review software changes.

## Goals

This framework is designed to:

- improve correctness of AI-assisted changes;
- preserve intended business behavior;
- reduce unnecessary code modifications;
- require investigation before implementation;
- improve test quality;
- introduce independent review;
- support legacy modernization and behavioral parity;
- keep humans in control of consequential actions;
- remain portable across AI development tools.

## Core Engineering Philosophy

For non-trivial work:

**Understand → Investigate → Plan → Implement → Test → Review → Correct → Verify → Human Approval**

Implementation is not complete merely because code compiles.

AI should have substantial freedom to analyze and work inside the development environment while maintaining strict boundaries around destructive or external actions.

## Repository Structure

```text
ai-engineering-framework/
├── standards/
├── agents/
├── workflows/
├── adapters/
│   ├── common/
│   ├── copilot/
│   ├── claude/
│   └── cursor/
└── scripts/
```

### `standards/`

Contains harness-independent engineering rules.

Current standards cover:

- development;
- testing;
- code review;
- security;
- legacy parity.

These files are the authoritative source for general engineering behavior.

### `agents/`

Defines specialized engineering roles.

Current roles:

- Planner
- Developer
- Tester
- Reviewer
- Legacy Parity Analyst

Agent definitions describe responsibilities and behavior independently of any particular AI vendor.

### `workflows/`

Defines repeatable engineering processes.

Current workflows:

- feature development;
- bug fixing;
- legacy modernization;
- code review.

Workflows coordinate the different engineering roles.

### `adapters/`

Contains integration templates for specific AI development harnesses.

The adapter layer currently contains support templates for:

- GitHub Copilot;
- Claude;
- Cursor.

Adapters should remain relatively thin.

General engineering behavior belongs in `standards/`, `agents/`, and `workflows/`.

### `scripts/`

Reserved for installation, synchronization, validation, and update tooling.

The scripts layer will eventually allow the framework to be installed into application repositories without manually duplicating files.

## Source of Truth

The framework separates reusable engineering behavior from tool-specific integration.

The source-of-truth hierarchy is:

```text
standards/
agents/
workflows/
        ↓
     adapters/
        ↓
application repository
        ↓
AI harness
```

Do not maintain independent copies of engineering policy for each AI vendor when the behavior can be represented in the shared framework.

## Project-Specific Information

This repository must remain generic.

Do not place application-specific information here, such as:

- application architecture;
- database schema;
- business rules;
- customer information;
- internal URLs;
- credentials;
- production configuration;
- project-specific legacy behavior.

That information belongs in the application repository.

A project using this framework may contain files such as:

```text
AI.md

.ai/
├── project.md
├── architecture.md
├── business-rules.md
├── database.md
└── legacy.md
```

The reusable framework defines **how AI should engineer software**.

The application repository defines **how that particular system works**.

## Instruction Precedence

When instructions conflict, apply the following order:

1. Explicit human instruction for the current task
2. Mandatory project-specific requirements
3. Project architecture and business rules
4. Shared AI engineering framework
5. AI harness defaults

Security and data-integrity safeguards must not be implicitly overridden.

## Engineering Roles

### Planner

Investigates the requirement and affected system.

Produces an implementation plan before production code is modified.

### Developer

Implements an approved change using the smallest correct modification.

### Tester

Acts adversarially and attempts to expose defects and regressions.

### Reviewer

Independently evaluates the implementation for correctness and risk.

### Legacy Parity Analyst

Compares modern implementations against authoritative legacy behavior.

## Harness Independence

The framework is intentionally vendor-independent.

AI tools are consumers of the framework rather than owners of the engineering standards.

Changing from one AI development tool to another should require changing an adapter rather than rewriting engineering policy.

## Human Control

AI may assist with:

- repository investigation;
- implementation planning;
- code modification;
- test creation;
- builds;
- test execution;
- static analysis;
- code review.

Consequential actions should remain explicitly controlled.

Examples include:

- production changes;
- destructive database operations;
- schema migrations;
- pushing commits;
- merging pull requests;
- deployment;
- infrastructure changes.

## Future Automation

The `scripts/` directory will provide commands for installing and updating the framework in application repositories.

The intended workflow is approximately:

```powershell
.\scripts\install.ps1 C:\Source\MyApplication
```

The installer will generate or synchronize the appropriate harness-specific files while preserving project-specific configuration.

## Design Principle

The framework should make AI behave more like a disciplined engineering team and less like an autocomplete system.

**Correctness and evidence are more important than the amount of code generated.**