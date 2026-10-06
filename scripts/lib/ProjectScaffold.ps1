#
# AI Engineering Framework - persistent project knowledge scaffold (.ai/).
#
# Harness-independent. Dot-sourced by scripts/install.ps1. Every file is
# project-owned: created once and never overwritten, even with -Force.
#

$ProjectKnowledgeFiles = @(
    ".ai/README.md",
    ".ai/project.md",
    ".ai/architecture.md",
    ".ai/business-rules/README.md",
    ".ai/components/README.md",
    ".ai/database/README.md",
    ".ai/integrations/README.md",
    ".ai/legacy/README.md",
    ".ai/decisions/README.md",
    ".ai/tasks/README.md"
)

# ===========================================================================
# Persistent project knowledge scaffold
# ===========================================================================

function Install-ProjectScaffolding {

    Write-Step "Creating persistent project knowledge scaffold"

    $readmeContent = @'
# Project AI Knowledge

This directory contains persistent engineering knowledge for this repository.

Its purpose is to preserve project-specific context across development
sessions, AI conversations, engineers, and specialized AI agents.

This directory describes how this specific system works.

Generic engineering standards belong in the shared AI Engineering Framework,
not here.

## Structure

- `project.md` - project purpose, technology, terminology, repository layout,
  constraints, and verification commands.
- `architecture.md` - architecture, boundaries, dependency direction, and
  architectural constraints.
- `business-rules/` - durable observable business behavior.
- `components/` - important application components and responsibilities.
- `database/` - persistence behavior and database constraints.
- `integrations/` - external-system and messaging behavior.
- `legacy/` - authoritative legacy behavior and parity information.
- `decisions/` - durable engineering decisions and rationale.
- `tasks/` - active engineering context that must survive sessions.

## Evidence

Project documentation provides engineering context but may become outdated.

When documentation conflicts with source code, executable tests, database
constraints, integration contracts, or observed runtime behavior, investigate
the discrepancy.

Do not silently assume documentation or implementation is correct.

## Durable vs Temporary Knowledge

Durable knowledge belongs in the appropriate project knowledge document.

Examples:

- confirmed business rules;
- architectural constraints;
- confirmed database behavior;
- integration contracts;
- intentional legacy differences;
- accepted engineering decisions.

Temporary task information belongs under `tasks/`.

Examples:

- hypotheses;
- debugging observations;
- failed approaches;
- intermediate investigation results;
- unresolved questions.

Do not promote unconfirmed hypotheses into durable project knowledge.

## Security

Do not store passwords, API keys, access tokens, private certificates,
connection-string secrets, production credentials, or other authentication
material in this directory.
'@

    $projectContent = @'
# Project

## Purpose

Describe what this application or service does and the business capability
it supports.

## Primary Technologies

Document the major languages, frameworks, platforms, infrastructure, and
persistence technologies.

## Repository Structure

Describe important projects, directories, entry points, and boundaries.

## Domain Terminology

Document project-specific terms and their meanings.

Prefer business terminology over implementation terminology.

## Important Constraints

Document high-level constraints future engineers must understand.

## Verification

### Build

Add the authoritative build command.

### Unit Tests

Add the authoritative unit-test command.

### Integration Tests

Add the authoritative integration-test command.

### Additional Verification

Document linting, static analysis, or other required verification.

## Related Knowledge

Point to important documents under `.ai/` when appropriate.
'@

    $architectureContent = @'
# Architecture

## Overview

Describe the high-level architecture of this system.

## Major Components

Describe the major application components and their responsibilities.

Detailed component documentation may live under `.ai/components/`.

## Dependency Direction

Describe important dependency rules.

## Execution Flows

Document important high-level execution flows.

Avoid duplicating implementation details that are obvious from source code.

## Architectural Patterns

Document patterns that new code should follow.

Only document patterns actually used by this project.

## Persistence Architecture

Summarize persistence responsibilities and point to `.ai/database/` for
details.

## Integration Architecture

Summarize external-system boundaries and point to `.ai/integrations/`.

## Constraints

Document architectural constraints that future changes must preserve.

## Known Technical Debt

Document technical debt only when it materially affects future engineering
decisions.
'@

    $businessRulesReadme = @'
# Business Rules

This directory contains durable observable business behavior.

Create separate files by meaningful business capability.

Examples:

- `shipping-import.md`
- `settlements.md`
- `fulfillment.md`
- `shipping-export.md`

A useful document structure is:

- Purpose
- Inputs
- Preconditions
- Business Rules
- State Transitions
- Persistence Effects
- Duplicate / Repeated Execution Behavior
- Failure Behavior
- Edge Cases
- Legacy Behavior
- Known Intentional Differences
- Evidence

Business-rule documentation should answer:

"What behavior must future implementations preserve?"

Avoid documenting implementation details that are already obvious from
source code.
'@

    $componentsReadme = @'
# Components

Document important application components whose responsibilities or
interactions are not obvious from source code alone.

Examples:

- `import-job.md`
- `sales-api.md`
- `shipping-handler.md`

Useful topics include:

- responsibility;
- inputs;
- outputs;
- important collaborators;
- execution lifecycle;
- persistence responsibility;
- integration responsibility;
- concurrency model;
- important invariants;
- related business rules.

Do not create documentation for every class.

Document components when the knowledge materially helps future engineering
work.
'@

    $databaseReadme = @'
# Database

This directory contains persistence knowledge that materially affects
engineering behavior.

Document topics such as:

- important tables;
- stored procedures;
- views;
- triggers;
- constraints;
- transaction boundaries;
- concurrency behavior;
- duplicate handling;
- idempotency;
- database-generated values;
- environment-specific differences;
- legacy persistence behavior.

Prefer separate documents for meaningful persistence areas.

Examples:

- `shipping-import.md`
- `settlements.md`
- `fulfillment.md`

Do not store database credentials or secrets here.

When database behavior is part of a business rule, link to the relevant
business-rule document rather than unnecessarily duplicating it.
'@

    $integrationsReadme = @'
# Integrations

Document external systems and integration behavior that future changes must
understand.

Examples:

- `service-bus.md`
- `sales-api.md`
- `payment-provider.md`
- `file-import.md`

Useful topics include:

- purpose;
- direction of communication;
- message or request contract;
- expected responses;
- retries;
- timeout behavior;
- duplicate delivery behavior;
- idempotency;
- failure handling;
- authentication approach without secrets;
- ordering requirements;
- transaction implications;
- local persistence effects.

Do not store credentials, access tokens, or secrets.
'@

    $legacyReadme = @'
# Legacy System Knowledge

This directory contains knowledge about authoritative legacy behavior used
during modernization or parity analysis.

Examples:

- `foxpro-overview.md`
- `import-parity.md`
- `known-differences.md`

Document:

- authoritative legacy source locations;
- important execution flows;
- observable business behavior;
- defaults;
- edge cases;
- persistence effects;
- external integrations;
- known legacy defects that must currently be preserved;
- intentional modernization differences;
- unresolved parity questions.

Do not assume old implementation structure should be reproduced.

Parity concerns observable behavior unless an explicit requirement states
otherwise.
'@

    $decisionsReadme = @'
# Engineering Decisions

This directory contains durable engineering decisions.

Use decision records when future engineers or AI agents may reasonably ask:

"Why was this implemented this way?"

Suggested naming:

- `001-short-description.md`
- `002-short-description.md`
- `003-short-description.md`

Suggested document structure:

# Decision Title

## Status

Proposed | Accepted | Superseded | Rejected

## Context

What problem or constraint required a decision?

## Decision

What was decided?

## Rationale

Why was this approach selected?

## Constraints

What must future changes preserve?

## Alternatives Considered

What meaningful alternatives were rejected and why?

## Verification

How can future changes verify they still satisfy this decision?

Do not create decision records for trivial implementation choices.
'@

    $tasksReadme = @'
# Active Engineering Tasks

This directory preserves working context for significant engineering work
across sessions and specialized agents.

Task documents are temporary working memory.

Examples:

- `settlements-not-created.md`
- `shipping-import-performance.md`
- `ado-1234567.md`

Suggested document structure:

# Task

## Status

Active | Blocked | Ready for Review | Complete

## Requirement / Problem

## Relevant Project Knowledge

## Confirmed Evidence

## Hypotheses

## Root Cause

## Relevant Files

## Plan

## Implementation

## Tests

## Review Findings

## Decisions Made During This Task

## Unresolved Questions

## Next Steps

## Durable Knowledge Candidates

Clearly distinguish confirmed evidence from hypotheses.

Do not treat task documents as authoritative business documentation.

When a task establishes durable knowledge, update the appropriate project
knowledge document or create a decision record.

Completed task documents may be retained when useful for historical context
or removed according to the repository team's preferred workflow.
'@

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "README.md") `
        -Content $readmeContent

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "project.md") `
        -Content $projectContent

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "architecture.md") `
        -Content $architectureContent

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "business-rules/README.md") `
        -Content $businessRulesReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "components/README.md") `
        -Content $componentsReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "database/README.md") `
        -Content $databaseReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "integrations/README.md") `
        -Content $integrationsReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "legacy/README.md") `
        -Content $legacyReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "decisions/README.md") `
        -Content $decisionsReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "tasks/README.md") `
        -Content $tasksReadme
}

# ===========================================================================
