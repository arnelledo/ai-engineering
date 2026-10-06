<#
.SYNOPSIS
    Installs the AI Engineering Framework into an application repository.

.DESCRIPTION
    Generates GitHub Copilot-native configuration from the canonical
    framework sources:

        standards/
        agents/
        workflows/

        prompts/

    The framework repository remains the source of truth.

    Generated (framework-owned) Copilot files are written to:

        .github/copilot-instructions.md
        .github/agents/
        .github/prompts/

    Project-owned files are created once and never overwritten:

        .github/instructions/project.instructions.md
        .ai/

    The target must be the root of a Git repository, because Copilot reads
    .github/ only from the repository root.

    The framework manifest (.ai/framework-manifest.json) records the
    framework commit and a hash of every generated file. On later runs it
    is used to warn about locally modified generated files and to remove
    generated files that the framework no longer produces.

    All files are written as UTF-8 without a byte-order mark, with LF line
    endings.

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

$TargetRepo = [System.IO.Path]::GetFullPath($TargetRepo).TrimEnd('\', '/')

$GitHubRoot = Join-Path $TargetRepo ".github"
$TargetAgentsRoot = Join-Path $GitHubRoot "agents"
$TargetPromptsRoot = Join-Path $GitHubRoot "prompts"
$TargetInstructionsRoot = Join-Path $GitHubRoot "instructions"

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

function Test-GitAvailable {
    return [bool](Get-Command git -ErrorAction SilentlyContinue)
}

function Invoke-GitQuery {
    # Runs a read-only git command and returns trimmed stdout, or $null on
    # failure. ErrorActionPreference is relaxed locally because Windows
    # PowerShell 5.1 turns native stderr output into terminating errors
    # when ErrorActionPreference is Stop.

    param(
        [string]$RepositoryPath,
        [string[]]$Arguments
    )

    if (-not (Test-GitAvailable)) {
        return $null
    }

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $output = & git -C $RepositoryPath @Arguments 2>$null

        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        return (($output | Out-String).Trim())
    }
    catch {
        return $null
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Test-SamePath {
    param(
        [string]$First,
        [string]$Second
    )

    $a = [System.IO.Path]::GetFullPath($First).TrimEnd('\', '/')
    $b = [System.IO.Path]::GetFullPath($Second).TrimEnd('\', '/')

    return [string]::Equals(
        $a,
        $b,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Assert-RepositoryRoot {
    # Copilot reads .github/ only from the repository root. Installing into
    # a subdirectory would produce files that Copilot silently ignores.

    param([string]$Path)

    $topLevel = Invoke-GitQuery `
        -RepositoryPath $Path `
        -Arguments @("rev-parse", "--show-toplevel")

    if ($topLevel) {

        if (-not (Test-SamePath $topLevel $Path)) {
            $suggested = [System.IO.Path]::GetFullPath($topLevel)
            throw "Target must be the root of a Git repository. Copilot only reads .github/ from the repository root. Repository root: $suggested"
        }

        return
    }

    # git is unavailable or the query failed: require .git directly in the
    # target (a directory, or a file for worktrees and submodules).

    if (-not (Test-Path -LiteralPath (Join-Path $Path ".git"))) {
        throw "Target must be the root of a Git repository (no .git found directly in $Path)."
    }
}

function Get-FrameworkVersion {

    $commit = Invoke-GitQuery `
        -RepositoryPath $FrameworkRoot `
        -Arguments @("rev-parse", "HEAD")

    if (-not $commit) {
        return [ordered]@{
            commit = "unknown"
            uncommittedChanges = $null
        }
    }

    $status = Invoke-GitQuery `
        -RepositoryPath $FrameworkRoot `
        -Arguments @("status", "--porcelain")

    return [ordered]@{
        commit = $commit
        uncommittedChanges = -not [string]::IsNullOrWhiteSpace($status)
    }
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

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function ConvertTo-NormalizedText {
    # LF line endings, no BOM character, single trailing newline.

    param([string]$Content)

    $text = $Content.TrimStart([char]0xFEFF)
    $text = $text -replace "`r`n", "`n"
    $text = $text -replace "`r", "`n"

    return $text.TrimEnd("`n") + "`n"
}

function Get-TextHash {
    param([string]$Content)

    $normalized = ConvertTo-NormalizedText $Content
    $bytes = $Utf8NoBom.GetBytes($normalized)
    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    return (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Get-FileTextHash {
    # Hash of a file's normalized text, so that Git line-ending conversion
    # or a BOM does not register as a local modification.

    param([string]$Path)

    $content = [System.IO.File]::ReadAllText($Path, $Utf8NoBom)

    return Get-TextHash $content
}

function Get-RepositoryRelativePath {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    $prefix = $TargetRepo + [System.IO.Path]::DirectorySeparatorChar

    if (-not $full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the target repository: $Path"
    }

    return $full.Substring($prefix.Length).Replace('\', '/')
}

function Write-TextFileNoBom {
    param(
        [string]$Path,
        [string]$Content
    )

    [System.IO.File]::WriteAllText(
        $Path,
        (ConvertTo-NormalizedText $Content),
        $Utf8NoBom
    )
}

# Generated files produced by this run: relative path -> content hash.
$GeneratedFiles = [ordered]@{}

# Generated files recorded by the previous installation manifest.
$PreviousGeneratedFiles = @{}

function Write-GeneratedFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $relativePath = Get-RepositoryRelativePath $Path
    $hash = Get-TextHash $Content

    $GeneratedFiles[$relativePath] = $hash

    $parent = Split-Path -Parent $Path

    Ensure-Directory -Path $parent

    $exists = Test-Path -LiteralPath $Path

    if ($exists -and -not $Force) {
        Write-WarningMessage "Skipped existing generated file: $Path"
        return $false
    }

    if ($exists) {

        $currentHash = Get-FileTextHash $Path

        if ($currentHash -eq $hash) {
            Write-Info "Unchanged: $Path"
            return $true
        }

        if (
            $PreviousGeneratedFiles.ContainsKey($relativePath) -and
            $PreviousGeneratedFiles[$relativePath] -and
            $PreviousGeneratedFiles[$relativePath] -ne $currentHash
        ) {
            Write-WarningMessage "Local changes will be overwritten (file was modified after the last installation): $Path"
        }
    }

    if ($DryRun) {
        Write-Info "[DryRun] Generate: $Path"
        return $true
    }

    Write-TextFileNoBom -Path $Path -Content $Content

    Write-Success "Generated: $Path"

    return $true
}

function Write-ScaffoldFile {
    param(
        [string]$Path,
        [string]$Content
    )

    # Project-owned files belong to the application repository.
    # Never overwrite them, even when -Force is supplied.

    if (Test-Path -LiteralPath $Path) {
        Write-Info "Preserved project-owned file: $Path"
        return
    }

    $parent = Split-Path -Parent $Path

    Ensure-Directory -Path $parent

    if ($DryRun) {
        Write-Info "[DryRun] Create project scaffold: $Path"
        return
    }

    Write-TextFileNoBom -Path $Path -Content $Content

    Write-Success "Created project scaffold: $Path"
}

function Read-PreviousManifest {

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        return
    }

    try {
        $json = [System.IO.File]::ReadAllText($ManifestPath, $Utf8NoBom).TrimStart([char]0xFEFF)
        $manifest = $json | ConvertFrom-Json
    }
    catch {
        Write-WarningMessage "Could not read previous manifest; stale-file cleanup is skipped: $ManifestPath"
        return
    }

    if (-not ($manifest.PSObject.Properties.Name -contains "generated")) {
        return
    }

    foreach ($entry in @($manifest.generated)) {

        if ($entry -is [string]) {
            # Manifest written by an earlier installer version: no hashes.
            $PreviousGeneratedFiles[$entry] = $null
        }
        elseif ($entry.PSObject.Properties.Name -contains "path") {
            $PreviousGeneratedFiles[$entry.path] = $entry.sha256
        }
    }
}

function Remove-StaleGeneratedFiles {
    # Removes files generated by a previous installation that the current
    # framework no longer produces. Only unmodified files under .github/
    # are removed, and only when -Force is supplied.

    Write-Step "Checking for stale generated files"

    $stale = @(
        $PreviousGeneratedFiles.Keys |
            Where-Object { -not $GeneratedFiles.Contains($_) } |
            Sort-Object
    )

    if ($stale.Count -eq 0) {
        Write-Info "No stale generated files."
        return
    }

    foreach ($relativePath in $stale) {

        if (-not $relativePath.StartsWith(".github/")) {
            Write-WarningMessage "Not removing stale entry outside .github/: $relativePath"
            continue
        }

        $fullPath = Join-Path $TargetRepo ($relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))

        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            continue
        }

        $recordedHash = $PreviousGeneratedFiles[$relativePath]

        if (-not $recordedHash) {
            Write-WarningMessage "Stale generated file kept (no recorded hash to confirm it is unmodified). Remove manually if no longer needed: $relativePath"
            continue
        }

        if ((Get-FileTextHash $fullPath) -ne $recordedHash) {
            Write-WarningMessage "Stale generated file kept (modified after installation). Remove manually if no longer needed: $relativePath"
            continue
        }

        if (-not $Force) {
            Write-WarningMessage "Stale generated file (no longer produced by the framework). Run with -Force to remove: $relativePath"
            continue
        }

        if ($DryRun) {
            Write-Info "[DryRun] Remove stale generated file: $relativePath"
            continue
        }

        Remove-Item -LiteralPath $fullPath -Force

        Write-Success "Removed stale generated file: $relativePath"
    }
}

# ===========================================================================
# Copilot agent metadata
# ===========================================================================

# Tools use the cross-platform tool-set aliases understood by both
# VS Code and the Copilot coding agent on GitHub.com:
#
#   read    - read file contents
#   search  - search files, text, usages, and workspace changes
#   edit    - create and modify files
#   execute - run terminal commands (builds, tests, git)
#   agent   - invoke other custom agents as subagents
#   web     - fetch URLs / web search
#   todo    - manage a task list
#
# Unrecognized tool names are ignored by both harnesses.
#
# Read-only roles (planner, reviewer, legacy-parity) deliberately receive
# no edit or execute tools, so "do not modify code" is enforced by the
# harness rather than by instructions alone.
#
# Only the orchestrator receives the agent tool. Its Agents list must
# match the agent file names (the default agent name in Copilot).
#
# Standards lists the role-specific canonical standards appended to the
# agent. Every agent also receives $SharedAgentStandards. Agent files
# refer to these appended standards instead of repeating their content.

$SharedAgentStandards = @(
    "project-knowledge.md"
)

$SpecialistAgentNames = @(
    "planner",
    "developer",
    "tester",
    "reviewer",
    "legacy-parity"
)

$AgentMetadata = [ordered]@{
    "orchestrator" = @{
        Description = "Coordinates non-trivial engineering work across planning, implementation, testing, review, and legacy parity analysis."
        Tools = @("read", "search", "edit", "execute", "agent", "todo")
        Agents = $SpecialistAgentNames
    }

    "planner" = @{
        Description = "Investigates software changes and produces implementation plans without modifying production code."
        Tools = @("read", "search", "web")
    }

    "developer" = @{
        Description = "Implements approved software changes using minimal, correct, maintainable modifications."
        Tools = @("read", "search", "edit", "execute", "todo")
    }

    "tester" = @{
        Description = "Performs adversarial test analysis and creates tests designed to expose defects and regressions."
        Tools = @("read", "search", "edit", "execute", "todo")
        Standards = @("testing.md")
    }

    "reviewer" = @{
        Description = "Independently reviews software changes for correctness, risk, architecture, security, and test quality."
        Tools = @("read", "search")
        Standards = @("review.md")
    }

    "legacy-parity" = @{
        Description = "Compares modern implementations against authoritative legacy behavior and identifies parity differences."
        Tools = @("read", "search")
        Standards = @("legacy-parity.md")
    }
}

function Get-AgentStandards {
    # Role-specific standards first (they are what the agent body refers
    # to most), then the shared standards.

    param([string]$AgentName)

    $metadata = $AgentMetadata[$AgentName]
    $standards = @()

    if ($metadata.ContainsKey("Standards")) {
        $standards += $metadata.Standards
    }

    $standards += $SharedAgentStandards

    return $standards
}

function ConvertTo-YamlInlineList {
    param([string[]]$Items)

    if (-not $Items -or $Items.Count -eq 0) {
        return "[]"
    }

    $quoted = $Items | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }

    return "[" + ($quoted -join ", ") + "]"
}

function New-AgentContent {
    param(
        [string]$AgentName,
        [string]$Body
    )

    if (-not $AgentMetadata.Contains($AgentName)) {
        throw "No Copilot metadata configured for agent '$AgentName'."
    }

    $metadata = $AgentMetadata[$AgentName]

    if (-not $metadata.ContainsKey("Tools") -or $metadata.Tools.Count -eq 0) {
        throw "No Copilot tools configured for agent '$AgentName'. Every agent must declare an explicit tool list."
    }

    $frontmatter = @(
        "---",
        "description: `"$($metadata.Description)`"",
        "tools: $(ConvertTo-YamlInlineList $metadata.Tools)"
    )

    if ($metadata.ContainsKey("Agents")) {

        if ($metadata.Tools -notcontains "agent") {
            throw "Agent '$AgentName' declares subagents but does not include the 'agent' tool."
        }

        foreach ($subagent in $metadata.Agents) {
            if (-not $AgentMetadata.Contains($subagent)) {
                throw "Agent '$AgentName' references unknown subagent '$subagent'."
            }
        }

        $frontmatter += "agents: $(ConvertTo-YamlInlineList $metadata.Agents)"
    }

    $frontmatter += "---"

    return ($frontmatter -join "`n") + "`n`n" + $Body
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

    "bootstrap-knowledge" = @{
        Description = "Bootstrap persistent project knowledge from repository evidence."
        Agent = "orchestrator"
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

# Canonical standards included in the repository-wide instructions, in
# order. Standards not listed here are role-specific and are delivered
# through the agents that need them.

$CopilotInstructionStandards = @(
    "development.md",
    "security.md",
    "project-knowledge.md",
    "human-control.md"
)

function New-CopilotInstructions {

    $sections = foreach ($standard in $CopilotInstructionStandards) {
        (Read-TextFile (Join-Path $StandardsRoot $standard)).Trim()
    }

    $header = @"
# AI Engineering Instructions

These instructions define the baseline engineering expectations for this
repository. This file is generated by the AI Engineering Framework installer
and is replaced on framework updates. Do not edit it directly.

Repository-specific instructions belong in
``.github/instructions/project.instructions.md``. Project-specific knowledge
belongs under ``.ai/``.

Project-specific architecture, business rules, persistence requirements,
and explicit task instructions take precedence over generic framework
guidance when they are more specific.
"@

    return (@($header.Trim()) + $sections) -join "`n`n"
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
# Project-owned Copilot instructions
# ===========================================================================

function Install-ProjectInstructions {

    # Repository-specific, always-applied Copilot rules. Owned by the
    # application repository: created once, never overwritten, even with
    # -Force. This is where teams customize Copilot behavior without
    # editing the framework-generated copilot-instructions.md.

    Write-Step "Creating project-owned Copilot instructions"

    $content = @'
---
applyTo: "**"
---

# Project Instructions

<!--
Repository-specific instructions for GitHub Copilot.

This file is owned by this repository. The AI Engineering Framework installer
creates it once and never overwrites it, so customizations here survive
framework updates. Do not edit .github/copilot-instructions.md instead; that
file is replaced on every framework update.

Keep this file short. It is applied to every Copilot request in this
repository. Add rules such as:

- authoritative build and test commands;
- repository-specific coding conventions;
- directories or files that must not be modified.

Durable project knowledge (business rules, architecture, persistence and
integration behavior) belongs under .ai/, not here.
-->
'@

    Write-ScaffoldFile `
        -Path (Join-Path $TargetInstructionsRoot "project.instructions.md") `
        -Content $content
}

# ===========================================================================
# Agent installation
# ===========================================================================

function Install-Agents {

    Write-Step "Generating Copilot custom agents"

    # Each agent receives its role-specific standards and the shared
    # standards, appended to its role definition. Delegated subagents start
    # with their own context and may not receive the repository-wide
    # instructions, so each agent must be self-contained. The text is
    # maintained once, in standards/.

    foreach ($agentName in $AgentMetadata.Keys) {

        $sourcePath = Join-Path `
            $AgentsRoot `
            "$agentName.md"

        $parts = @((Read-TextFile $sourcePath).Trim())

        foreach ($standard in (Get-AgentStandards $agentName)) {
            $parts += (Read-TextFile (Join-Path $StandardsRoot $standard)).Trim()
        }

        $body = $parts -join "`n`n"

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
        },
        @{
            Source = "bootstrap-knowledge.md"
            Destination = "bootstrap-knowledge.prompt.md"
            PromptName = "bootstrap-knowledge"
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

    # No timestamp: the manifest only changes when the framework commit or
    # the generated content changes, which keeps Git diffs meaningful.

    $generated = @(
        $GeneratedFiles.Keys | Sort-Object | ForEach-Object {
            [ordered]@{
                path = $_
                sha256 = $GeneratedFiles[$_]
            }
        }
    )

    $manifest = [ordered]@{
        framework = "ai-engineering-framework"
        manifestVersion = 2
        harness = "github-copilot"
        frameworkVersion = Get-FrameworkVersion
        generated = $generated
        projectOwned = @(
            ".github/instructions/project.instructions.md",
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

    if ($manifest.frameworkVersion.uncommittedChanges) {
        Write-WarningMessage "The framework repository has uncommitted changes. The recorded commit does not fully describe the installed content."
    }

    $json = $manifest | ConvertTo-Json -Depth 10

    # The manifest is not recorded in its own generated-file list.

    if ((Test-Path -LiteralPath $ManifestPath) -and -not $Force) {
        Write-WarningMessage "Skipped existing manifest: $ManifestPath"
        return
    }

    if (
        (Test-Path -LiteralPath $ManifestPath) -and
        ((Get-FileTextHash $ManifestPath) -eq (Get-TextHash $json))
    ) {
        Write-Info "Unchanged: $ManifestPath"
        return
    }

    if ($DryRun) {
        Write-Info "[DryRun] Write manifest: $ManifestPath"
        return
    }

    Write-TextFileNoBom -Path $ManifestPath -Content $json

    Write-Success "Written: $ManifestPath"
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

if (Test-SamePath $TargetRepo $FrameworkRoot) {
    throw "Target repository cannot be the framework repository itself."
}

Assert-RepositoryRoot -Path $TargetRepo

$requiredFiles = @(
    (Join-Path $StandardsRoot "development.md"),
    (Join-Path $StandardsRoot "security.md"),
    (Join-Path $StandardsRoot "project-knowledge.md"),
    (Join-Path $StandardsRoot "human-control.md"),

    (Join-Path $AgentsRoot "orchestrator.md"),
    (Join-Path $AgentsRoot "planner.md"),
    (Join-Path $AgentsRoot "developer.md"),
    (Join-Path $AgentsRoot "tester.md"),
    (Join-Path $AgentsRoot "reviewer.md"),
    (Join-Path $AgentsRoot "legacy-parity.md"),

    (Join-Path $WorkflowsRoot "feature.md"),
    (Join-Path $WorkflowsRoot "bug-fix.md"),
    (Join-Path $WorkflowsRoot "migration.md"),
    (Join-Path $WorkflowsRoot "code-review.md"),

    (Join-Path $PromptsRoot "investigate.md"),
    (Join-Path $PromptsRoot "test.md"),
    (Join-Path $PromptsRoot "parity.md"),
    (Join-Path $PromptsRoot "bootstrap-knowledge.md")
)

# Every standard referenced by the agents or the repository-wide
# instructions must exist.

foreach ($agentName in $AgentMetadata.Keys) {
    foreach ($standard in (Get-AgentStandards $agentName)) {
        $requiredFiles += (Join-Path $StandardsRoot $standard)
    }
}

foreach ($standard in $CopilotInstructionStandards) {
    $requiredFiles += (Join-Path $StandardsRoot $standard)
}

# Every canonical standard must be delivered somewhere. A standard that no
# agent and no instruction file uses would silently never reach the
# target repository.

$deliveredStandards = @($CopilotInstructionStandards)

foreach ($agentName in $AgentMetadata.Keys) {
    $deliveredStandards += Get-AgentStandards $agentName
}

$undeliveredStandards = @(
    Get-ChildItem -LiteralPath $StandardsRoot -Filter "*.md" -File |
        Where-Object { $deliveredStandards -notcontains $_.Name } |
        ForEach-Object { $_.Name }
)

if ($undeliveredStandards.Count -gt 0) {
    throw "These standards are not delivered to any agent or instruction file: $($undeliveredStandards -join ', '). Add them to `$CopilotInstructionStandards or an agent's Standards list in install.ps1."
}

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

Read-PreviousManifest

Write-Step "Generating repository Copilot instructions"

$copilotInstructions = New-CopilotInstructions

Write-GeneratedFile `
    -Path (Join-Path $GitHubRoot "copilot-instructions.md") `
    -Content $copilotInstructions | Out-Null

Install-Agents

Install-WorkflowPrompts

Install-SpecialistPrompts

Install-ProjectScaffolding

Install-ProjectInstructions

Remove-StaleGeneratedFiles

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
Write-Host "Next steps:"
Write-Host "  1. Open the repository in VS Code"
Write-Host "  2. Select the Orchestrator agent in Copilot Chat"
Write-Host "  3. Run /bootstrap-knowledge to discover and populate persistent project knowledge"
Write-Host "  4. Review the generated .ai/ knowledge"
Write-Host "  5. Use the Reviewer agent to independently validate the initial knowledge when appropriate"
Write-Host "  6. Correct any unsupported or inaccurate claims"
Write-Host "  7. Add repository-specific Copilot rules to .github/instructions/project.instructions.md"
Write-Host "  8. Commit .github/ and reviewed .ai/ knowledge with the application repository"
Write-Host "  9. Continue normal development using the Orchestrator"
