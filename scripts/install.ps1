<#
.SYNOPSIS
    Installs the AI Engineering Framework into an application repository.

.DESCRIPTION
    Generates GitHub Copilot-native configuration from the canonical
    framework sources:

        standards/
        agents/
        workflows/

    The framework repository remains the source of truth.

    Generated Copilot files are written to:

        .github/copilot-instructions.md
        .github/agents/
        .github/prompts/

    Persistent project-specific engineering knowledge is scaffolded under:

        .ai/

    Existing project knowledge under .ai/ is never overwritten.

.EXAMPLE
    .\scripts\install.ps1 `
        -TargetRepo "C:\Source\MyApplication"

.EXAMPLE
    .\scripts\install.ps1 `
        -TargetRepo "C:\Source\MyApplication" `
        -DryRun

.EXAMPLE
    .\scripts\install.ps1 `
        -TargetRepo "C:\Source\MyApplication" `
        -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetRepo,

    [switch]$Force,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ===========================================================================
# Paths
# ===========================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$FrameworkRoot = Split-Path -Parent $ScriptRoot

$StandardsRoot = Join-Path $FrameworkRoot "standards"
$AgentsRoot = Join-Path $FrameworkRoot "agents"
$WorkflowsRoot = Join-Path $FrameworkRoot "workflows"
$PromptsRoot = Join-Path $FrameworkRoot "prompts"

$TargetRepo = [System.IO.Path]::GetFullPath($TargetRepo)

$GitHubRoot = Join-Path $TargetRepo ".github"
$TargetAgentsRoot = Join-Path $GitHubRoot "agents"
$TargetPromptsRoot = Join-Path $GitHubRoot "prompts"

$TargetAiRoot = Join-Path $TargetRepo ".ai"

$ManifestPath = Join-Path $TargetAiRoot "framework-manifest.json"

# ===========================================================================
# Console helpers
# ===========================================================================

function Write-Step {
    param([string]$Message)

    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)

    Write-Host "    $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)

    Write-Host "    $Message" -ForegroundColor Gray
}

function Write-WarningMessage {
    param([string]$Message)

    Write-Host "    WARNING: $Message" -ForegroundColor Yellow
}

# ===========================================================================
# Validation
# ===========================================================================

function Assert-DirectoryExists {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Description does not exist: $Path"
    }
}

function Assert-FileExists {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description does not exist: $Path"
    }
}

function Test-IsGitRepository {
    param([string]$Path)

    $current = $Path

    while ($current) {

        $gitPath = Join-Path $current ".git"

        if (Test-Path -LiteralPath $gitPath) {
            return $true
        }

        $parent = Split-Path -Parent $current

        if (
            [string]::IsNullOrWhiteSpace($parent) -or
            $parent -eq $current
        ) {
            break
        }

        $current = $parent
    }

    return $false
}

# ===========================================================================
# File helpers
# ===========================================================================

function Ensure-Directory {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path -PathType Container) {
        return
    }

    if ($DryRun) {
        Write-Info "[DryRun] Create directory: $Path"
        return
    }

    New-Item `
        -ItemType Directory `
        -Path $Path `
        -Force | Out-Null
}

function Read-TextFile {
    param([string]$Path)

    Assert-FileExists `
        -Path $Path `
        -Description "Required source file"

    return Get-Content `
        -LiteralPath $Path `
        -Raw `
        -Encoding UTF8
}

function Write-GeneratedFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $parent = Split-Path -Parent $Path

    Ensure-Directory -Path $parent

    if (
        (Test-Path -LiteralPath $Path) -and
        -not $Force
    ) {
        Write-WarningMessage "Skipped existing generated file: $Path"
        return $false
    }

    if ($DryRun) {
        Write-Info "[DryRun] Generate: $Path"
        return $true
    }

    Set-Content `
        -LiteralPath $Path `
        -Value $Content `
        -Encoding UTF8

    Write-Success "Generated: $Path"

    return $true
}

function Write-ScaffoldFile {
    param(
        [string]$Path,
        [string]$Content
    )

    # Project knowledge is owned by the application repository.
    # Never overwrite it, even when -Force is supplied.

    if (Test-Path -LiteralPath $Path) {
        Write-Info "Preserved project knowledge: $Path"
        return
    }

    $parent = Split-Path -Parent $Path

    Ensure-Directory -Path $parent

    if ($DryRun) {
        Write-Info "[DryRun] Create project scaffold: $Path"
        return
    }

    Set-Content `
        -LiteralPath $Path `
        -Value $Content `
        -Encoding UTF8

    Write-Success "Created project scaffold: $Path"
}

# ===========================================================================
# Copilot agent metadata
# ===========================================================================

$AgentMetadata = @{
    "orchestrator" = @{
        Description = "Coordinates non-trivial engineering work across planning, implementation, testing, review, and legacy parity analysis."
    }

    "planner" = @{
        Description = "Investigates software changes and produces implementation plans without modifying production code."
    }

    "developer" = @{
        Description = "Implements approved software changes using minimal, correct, maintainable modifications."
    }

    "tester" = @{
        Description = "Performs adversarial test analysis and creates tests designed to expose defects and regressions."
    }

    "reviewer" = @{
        Description = "Independently reviews software changes for correctness, risk, architecture, security, and test quality."
    }

    "legacy-parity" = @{
        Description = "Compares modern implementations against authoritative legacy behavior and identifies parity differences."
    }
}

function New-AgentContent {
    param(
        [string]$AgentName,
        [string]$Body
    )

    if (-not $AgentMetadata.ContainsKey($AgentName)) {
        throw "No Copilot metadata configured for agent '$AgentName'."
    }

    $description = $AgentMetadata[$AgentName].Description

    return @"
---
description: "$description"
---

$Body
"@
}

# ===========================================================================
# Copilot workflow prompt metadata
# ===========================================================================

$PromptMetadata = @{
    "feature" = @{
        Description = "Implement a non-trivial feature using the framework feature-development workflow."
        Agent = "orchestrator"
    }

    "bug-fix" = @{
        Description = "Investigate and fix a defect using root-cause analysis, regression testing, implementation, and review."
        Agent = "orchestrator"
    }

    "migration" = @{
        Description = "Modernize legacy behavior while explicitly verifying behavioral parity."
        Agent = "orchestrator"
    }

    "code-review" = @{
        Description = "Perform an independent engineering review of the current change."
        Agent = "reviewer"
    }

    "investigate" = @{
        Description = "Investigate a software problem without modifying production code."
        Agent = "planner"
    }

    "test" = @{
        Description = "Perform adversarial testing of the current implementation."
        Agent = "tester"
    }

    "parity" = @{
        Description = "Compare modern behavior against an authoritative legacy implementation."
        Agent = "legacy-parity"
    }
}

function New-PromptContent {
    param(
        [string]$PromptName,
        [string]$Body
    )

    if (-not $PromptMetadata.ContainsKey($PromptName)) {
        throw "No Copilot metadata configured for prompt '$PromptName'."
    }

    $metadata = $PromptMetadata[$PromptName]

    return @"
---
description: "$($metadata.Description)"
agent: "$($metadata.Agent)"
---

$Body
"@
}

# ===========================================================================
# Repository-wide Copilot instructions
# ===========================================================================

function New-CopilotInstructions {

    $development = Read-TextFile (
        Join-Path $StandardsRoot "development.md"
    )

    $security = Read-TextFile (
        Join-Path $StandardsRoot "security.md"
    )

    return @"
# AI Engineering Instructions

These instructions define the baseline engineering expectations for this
repository.

Project-specific architecture, business rules, persistence requirements,
and explicit task instructions take precedence over generic framework
guidance when they are more specific.

$development

$security

# Persistent Project Knowledge

Project-specific engineering knowledge is maintained under `.ai/`.

For non-trivial work, inspect relevant project knowledge before planning
or modifying code.

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

Do not load unrelated project knowledge unnecessarily.

Project documentation provides context but may become outdated.

Source code, executable tests, database constraints, integration contracts,
and observed behavior may provide stronger evidence.

When documentation materially conflicts with executable evidence:

1. identify the discrepancy;
2. investigate which behavior is authoritative;
3. report the discrepancy;
4. do not silently choose an interpretation.

Do not invent project-specific behavior when evidence is unavailable.

# Active Task Continuity

For significant work spanning multiple phases or sessions, use an active
task document under `.ai/tasks/`.

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

Task documents are working context and are not automatically authoritative
business documentation.

# Knowledge Maintenance

At the completion of significant work, determine whether durable project
knowledge was discovered or changed.

Examples include:

- confirmed business rules;
- persistence constraints;
- integration behavior;
- architectural decisions;
- intentional legacy differences;
- concurrency requirements;
- important operational constraints.

Update durable project knowledge only when sufficiently supported by
evidence.

Do not convert debugging hypotheses, temporary observations, or speculation
into permanent project documentation.

# Engineering Workflow

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

# Human Control

Do not perform consequential external or destructive actions without
explicit authorization.

This includes:

- production deployment;
- destructive database operations;
- pushing commits;
- merging pull requests;
- production infrastructure changes;
- unrelated dependency upgrades;
- unrelated CI/CD modifications.

Compilation alone is not sufficient evidence that a task is complete.
"@
}

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
        -Path (Join-Path $TargetAiRoot "business-rules\README.md") `
        -Content $businessRulesReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "components\README.md") `
        -Content $componentsReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "database\README.md") `
        -Content $databaseReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "integrations\README.md") `
        -Content $integrationsReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "legacy\README.md") `
        -Content $legacyReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "decisions\README.md") `
        -Content $decisionsReadme

    Write-ScaffoldFile `
        -Path (Join-Path $TargetAiRoot "tasks\README.md") `
        -Content $tasksReadme
}

# ===========================================================================
# Agent installation
# ===========================================================================

function Install-Agents {

    Write-Step "Generating Copilot custom agents"

    $agentNames = @(
        "orchestrator",
        "planner",
        "developer",
        "tester",
        "reviewer",
        "legacy-parity"
    )

    foreach ($agentName in $agentNames) {

        $sourcePath = Join-Path `
            $AgentsRoot `
            "$agentName.md"

        $body = Read-TextFile $sourcePath

        $content = New-AgentContent `
            -AgentName $agentName `
            -Body $body

        $destination = Join-Path `
            $TargetAgentsRoot `
            "$agentName.agent.md"

        Write-GeneratedFile `
            -Path $destination `
            -Content $content | Out-Null
    }
}

# ===========================================================================
# Workflow prompt installation
# ===========================================================================

function Install-WorkflowPrompts {

    Write-Step "Generating Copilot workflow prompts"

    $workflowMappings = @(
        @{
            Source = "feature.md"
            Destination = "feature.prompt.md"
            PromptName = "feature"
        },
        @{
            Source = "bug-fix.md"
            Destination = "bug-fix.prompt.md"
            PromptName = "bug-fix"
        },
        @{
            Source = "migration.md"
            Destination = "migration.prompt.md"
            PromptName = "migration"
        },
        @{
            Source = "code-review.md"
            Destination = "review.prompt.md"
            PromptName = "code-review"
        }
    )

    foreach ($mapping in $workflowMappings) {

        $sourcePath = Join-Path `
            $WorkflowsRoot `
            $mapping.Source

        $body = Read-TextFile $sourcePath

        $content = New-PromptContent `
            -PromptName $mapping.PromptName `
            -Body $body

        $destination = Join-Path `
            $TargetPromptsRoot `
            $mapping.Destination

        Write-GeneratedFile `
            -Path $destination `
            -Content $content | Out-Null
    }
}

# ===========================================================================
# Specialist prompt installation
# ===========================================================================

function Install-SpecialistPrompts {

    Write-Step "Generating specialist Copilot prompts"

    $promptMappings = @(
        @{
            Source = "investigate.md"
            Destination = "investigate.prompt.md"
            PromptName = "investigate"
        },
        @{
            Source = "test.md"
            Destination = "test.prompt.md"
            PromptName = "test"
        },
        @{
            Source = "parity.md"
            Destination = "parity.prompt.md"
            PromptName = "parity"
        }
    )

    foreach ($mapping in $promptMappings) {

        $sourcePath = Join-Path `
            $PromptsRoot `
            $mapping.Source

        $body = Read-TextFile $sourcePath

        $content = New-PromptContent `
            -PromptName $mapping.PromptName `
            -Body $body

        $destination = Join-Path `
            $TargetPromptsRoot `
            $mapping.Destination

        Write-GeneratedFile `
            -Path $destination `
            -Content $content | Out-Null
    }
}

# ===========================================================================
# Manifest
# ===========================================================================

function Install-Manifest {

    Write-Step "Writing framework manifest"

    $manifest = [ordered]@{
        framework = "ai-engineering-framework"
        installedAtUtc = [DateTime]::UtcNow.ToString("o")
        frameworkSource = "ai-engineering-framework"
        harness = "github-copilot"

        generated = @(
            ".github/copilot-instructions.md",
            ".github/agents/orchestrator.agent.md",
            ".github/agents/planner.agent.md",
            ".github/agents/developer.agent.md",
            ".github/agents/tester.agent.md",
            ".github/agents/reviewer.agent.md",
            ".github/agents/legacy-parity.agent.md",
            ".github/prompts/feature.prompt.md",
            ".github/prompts/bug-fix.prompt.md",
            ".github/prompts/migration.prompt.md",
            ".github/prompts/investigate.prompt.md",
            ".github/prompts/test.prompt.md",
            ".github/prompts/review.prompt.md",
            ".github/prompts/parity.prompt.md"
        )

        projectKnowledge = @(
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
    }

    $json = $manifest | ConvertTo-Json -Depth 10

    Write-GeneratedFile `
        -Path $ManifestPath `
        -Content $json | Out-Null
}

# ===========================================================================
# Main
# ===========================================================================

Write-Host ""
Write-Host "AI Engineering Framework Installer" -ForegroundColor White
Write-Host "==================================" -ForegroundColor White

Write-Info "Framework: $FrameworkRoot"
Write-Info "Target:    $TargetRepo"

if ($DryRun) {
    Write-WarningMessage "DryRun enabled. No files will be changed."
}

Write-Step "Validating framework"

Assert-DirectoryExists `
    -Path $StandardsRoot `
    -Description "Framework standards directory"

Assert-DirectoryExists `
    -Path $AgentsRoot `
    -Description "Framework agents directory"

Assert-DirectoryExists `
    -Path $WorkflowsRoot `
    -Description "Framework workflows directory"

Assert-DirectoryExists `
    -Path $PromptsRoot `
    -Description "Framework prompts directory"

Assert-DirectoryExists `
    -Path $TargetRepo `
    -Description "Target repository"

if (-not (Test-IsGitRepository -Path $TargetRepo)) {
    throw "Target path does not appear to be inside a Git repository: $TargetRepo"
}

$requiredFiles = @(
    (Join-Path $StandardsRoot "development.md"),
    (Join-Path $StandardsRoot "security.md"),

    (Join-Path $AgentsRoot "orchestrator.md"),
    (Join-Path $AgentsRoot "planner.md"),
    (Join-Path $AgentsRoot "developer.md"),
    (Join-Path $AgentsRoot "tester.md"),
    (Join-Path $AgentsRoot "reviewer.md"),
    (Join-Path $AgentsRoot "legacy-parity.md"),

    (Join-Path $WorkflowsRoot "feature.md"),
    (Join-Path $WorkflowsRoot "bug-fix.md"),
    (Join-Path $WorkflowsRoot "migration.md"),
    (Join-Path $WorkflowsRoot "code-review.md")

    (Join-Path $PromptsRoot "investigate.md"),
    (Join-Path $PromptsRoot "test.md"),
    (Join-Path $PromptsRoot "parity.md")
)

foreach ($file in $requiredFiles) {

    Assert-FileExists `
        -Path $file `
        -Description "Required framework file"
}

Write-Success "Framework validation passed."

Write-Step "Creating target directories"

Ensure-Directory $GitHubRoot
Ensure-Directory $TargetAgentsRoot
Ensure-Directory $TargetPromptsRoot
Ensure-Directory $TargetAiRoot

Write-Step "Generating repository Copilot instructions"

$copilotInstructions = New-CopilotInstructions

Write-GeneratedFile `
    -Path (Join-Path $GitHubRoot "copilot-instructions.md") `
    -Content $copilotInstructions | Out-Null

Install-Agents

Install-WorkflowPrompts

Install-SpecialistPrompts

Install-ProjectScaffolding

Install-Manifest

Write-Host ""
Write-Host "==================================" -ForegroundColor White

if ($DryRun) {
    Write-Host "Dry run completed successfully." -ForegroundColor Green
}
else {
    Write-Host "Framework installation completed." -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Complete .ai/project.md"
Write-Host "  2. Complete .ai/architecture.md"
Write-Host "  3. Add business rules under .ai/business-rules/"
Write-Host "  4. Add persistence knowledge under .ai/database/"
Write-Host "  5. Add integration knowledge under .ai/integrations/"
Write-Host "  6. Add legacy knowledge under .ai/legacy/ when applicable"
Write-Host "  7. Commit project knowledge with the application repository"
Write-Host "  8. Open the repository in VS Code"
Write-Host "  9. Test Copilot with /investigate"
Write-Host ""