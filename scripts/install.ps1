#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs the AI Engineering Framework into an application repository.

.DESCRIPTION
    Generates harness-native configuration from the canonical framework
    sources:

        standards/
        agents/
        workflows/
        prompts/
        scripts/framework.psd1

    The framework repository remains the source of truth. Harness-specific
    translation lives in adapters/<harness>/adapter.ps1.

    Supported harnesses (one per repository):

        GitHubCopilot   .github/copilot-instructions.md
                        .github/agents/
                        .github/prompts/
                        .github/instructions/project.instructions.md (project-owned)

        Claude          .claude/rules/ai-engineering.md
                        .claude/agents/
                        .claude/skills/

    Persistent project knowledge is scaffolded under .ai/ for every harness.
    Project-owned files are created once and never overwritten.

    A repository has one harness installed at a time. When -Harness is
    omitted, the harness recorded in the framework manifest is updated, or
    GitHubCopilot when there is none. Installing a different harness than
    the recorded one requires -Force; the previous harness's unmodified
    generated files are then removed.

    The target must be the root of a Git repository.

    The framework manifest (.ai/framework-manifest.json) records the
    harness, the framework commit, and a hash of every generated file. On
    later runs it is used to warn about locally modified generated files and
    to remove generated files that are no longer produced.

    All files are written as UTF-8 without a byte-order mark, with LF line
    endings.

.EXAMPLE
    .\scripts\install.ps1 `
        -TargetRepo "C:\Source\MyApplication"

.EXAMPLE
    .\scripts\install.ps1 `
        -TargetRepo "C:\Source\MyApplication" `
        -Harness Claude `
        -DryRun

.EXAMPLE
    .\scripts\install.ps1 `
        -TargetRepo "C:\Source\MyApplication" `
        -Force

.EXAMPLE
    # macOS / Linux (PowerShell 7)
    ./scripts/install.ps1 -TargetRepo ~/src/my-application -Harness Claude -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetRepo,

    [ValidateSet("GitHubCopilot", "Claude")]
    [string]$Harness,

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
$AdaptersRoot = Join-Path $FrameworkRoot "adapters"

$TargetRepo = [System.IO.Path]::GetFullPath($TargetRepo).TrimEnd('\', '/')

$TargetAiRoot = Join-Path $TargetRepo ".ai"

$ManifestPath = Join-Path $TargetAiRoot "framework-manifest.json"

# ===========================================================================
# Load framework model, helpers, and adapters
# ===========================================================================

. (Join-Path $ScriptRoot "lib/Common.ps1")
. (Join-Path $ScriptRoot "lib/ProjectScaffold.ps1")

$Framework = Import-PowerShellDataFile -Path (Join-Path $ScriptRoot "framework.psd1")

# Each adapter registers itself: $HarnessAdapters[<parameter value>] = @{...}
$HarnessAdapters = @{}

foreach ($adapterFile in (Get-ChildItem -LiteralPath $AdaptersRoot -Filter "adapter.ps1" -File -Recurse)) {
    . $adapterFile.FullName
}

function Get-AdapterById {
    param([string]$Id)

    foreach ($key in $HarnessAdapters.Keys) {
        if ($HarnessAdapters[$key].Id -eq $Id) {
            return $key
        }
    }

    return $null
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

Assert-DirectoryExists -Path $StandardsRoot -Description "Framework standards directory"
Assert-DirectoryExists -Path $AgentsRoot -Description "Framework agents directory"
Assert-DirectoryExists -Path $WorkflowsRoot -Description "Framework workflows directory"
Assert-DirectoryExists -Path $PromptsRoot -Description "Framework prompts directory"
Assert-DirectoryExists -Path $TargetRepo -Description "Target repository"

if (Test-SamePath $TargetRepo $FrameworkRoot) {
    throw "Target repository cannot be the framework repository itself."
}

Assert-RepositoryRoot -Path $TargetRepo

Assert-FrameworkModel

Write-Success "Framework validation passed."

# ---------------------------------------------------------------------------
# Resolve the harness (one per repository)
# ---------------------------------------------------------------------------

Read-PreviousManifest

$previousHarnessKey = $null

if ($PreviousHarnessId) {

    $previousHarnessKey = Get-AdapterById $PreviousHarnessId

    if (-not $previousHarnessKey) {
        throw "The framework manifest records an unknown harness '$PreviousHarnessId': $ManifestPath"
    }
}

if (-not $Harness) {
    if ($previousHarnessKey) {
        $Harness = $previousHarnessKey
    }
    else {
        $Harness = "GitHubCopilot"
    }
}

$Adapter = $HarnessAdapters[$Harness]

Write-Info "Harness:   $($Adapter.DisplayName)"

$isSwitch = $previousHarnessKey -and ($previousHarnessKey -ne $Harness)

if ($isSwitch) {

    $previousAdapter = $HarnessAdapters[$previousHarnessKey]

    if (-not $Force) {
        throw "This repository has the $($previousAdapter.DisplayName) harness installed. Only one harness can be installed at a time. Re-run with -Force to switch to $($Adapter.DisplayName); unmodified $($previousAdapter.DisplayName) generated files will be removed. Preview first with -DryRun -Force."
    }

    Write-WarningMessage "Switching harness from $($previousAdapter.DisplayName) to $($Adapter.DisplayName). Unmodified $($previousAdapter.DisplayName) generated files will be removed."

    $cleanupPrefixes = $previousAdapter.ManagedPrefixes
}
else {
    $cleanupPrefixes = $Adapter.ManagedPrefixes
}

# ---------------------------------------------------------------------------
# Generate
# ---------------------------------------------------------------------------

Write-Step "Creating target directories"

Ensure-Directory $TargetAiRoot

& $Adapter.InstallFunction

Install-ProjectScaffolding

Remove-StaleGeneratedFiles -ManagedPrefixes $cleanupPrefixes

Install-Manifest `
    -HarnessId $Adapter.Id `
    -ProjectOwned (@($Adapter.ProjectOwned) + $ProjectKnowledgeFiles)

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

$stepNumber = 1

foreach ($step in $Adapter.NextSteps) {
    Write-Host "  $stepNumber. $step"
    $stepNumber++
}
