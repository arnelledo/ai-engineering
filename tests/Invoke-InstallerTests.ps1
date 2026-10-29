#!/usr/bin/env pwsh
<#
.SYNOPSIS
    End-to-end tests for scripts/install.ps1.

.DESCRIPTION
    Copies the framework to a temporary directory, creates throwaway target
    repositories, runs the installer in child processes, and checks the
    results. Requires git. Nothing outside the temporary directory is
    modified.

    Runs on Windows PowerShell 5.1 and PowerShell 7.

.EXAMPLE
    .\tests\Invoke-InstallerTests.ps1

.EXAMPLE
    .\tests\Invoke-InstallerTests.ps1 -KeepTemp
#>

[CmdletBinding()]
param(
    [switch]$KeepTemp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$FrameworkSource = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$PowerShellExe = (Get-Process -Id $PID).Path
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("aie-tests-" + [guid]::NewGuid().ToString("N").Substring(0, 8))

$script:Passed = 0
$script:Failed = 0

# ===========================================================================
# Helpers
# ===========================================================================

function Write-TestHeader {
    param([string]$Name)
    Write-Host ""
    Write-Host "--- $Name" -ForegroundColor Cyan
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if ($Condition) {
        $script:Passed++
        Write-Host "  PASS  $Message" -ForegroundColor Green
    }
    else {
        $script:Failed++
        Write-Host "  FAIL  $Message" -ForegroundColor Red
    }
}

function Invoke-Git {
    param(
        [string]$Path,
        [string[]]$Arguments
    )

    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & git -C $Path @Arguments 2>&1 | Out-Null
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

function New-GitRepository {
    param([string]$Name)

    $path = Join-Path $TempRoot $Name
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Invoke-Git $path @("init", "-q")
    return $path
}

function Invoke-Installer {
    # Runs the installer in a child process. Returns exit code and output.

    param(
        [string]$Framework,
        [string]$Target,
        [string[]]$Arguments = @()
    )

    $installer = Join-Path $Framework "scripts/install.ps1"

    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $installer -TargetRepo $Target @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

function Get-RepoFile {
    param(
        [string]$Repo,
        [string]$RelativePath
    )

    return Join-Path $Repo ($RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
}

function Test-RepoFile {
    param(
        [string]$Repo,
        [string]$RelativePath
    )

    return Test-Path -LiteralPath (Get-RepoFile $Repo $RelativePath) -PathType Leaf
}

function Read-RepoFile {
    param(
        [string]$Repo,
        [string]$RelativePath
    )

    return [System.IO.File]::ReadAllText((Get-RepoFile $Repo $RelativePath))
}

function Read-Manifest {
    param([string]$Repo)

    return (Read-RepoFile $Repo ".ai/framework-manifest.json") | ConvertFrom-Json
}

function Get-GeneratedFileList {
    param([string]$Repo)

    $root = Join-Path $Repo ".github"
    $files = @()

    foreach ($dir in @(".github", ".claude")) {
        $full = Join-Path $Repo $dir
        if (Test-Path -LiteralPath $full) {
            $files += Get-ChildItem -LiteralPath $full -Recurse -File | ForEach-Object { $_.FullName }
        }
    }

    return $files
}

function Assert-FileFormat {
    # No BOM, no CR, single H1, frontmatter present for agents/prompts/skills.

    param(
        [string]$Repo,
        [string]$Label
    )

    $files = @(Get-GeneratedFileList $Repo | Where-Object { $_ -like "*.md" })

    $bom = @()
    $crlf = @()
    $multiH1 = @()
    $badFrontmatter = @()

    foreach ($file in $files) {

        $bytes = [System.IO.File]::ReadAllBytes($file)

        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $bom += $file
        }

        $text = [System.IO.File]::ReadAllText($file)

        if ($text.Contains("`r")) {
            $crlf += $file
        }

        $inFence = $false
        $h1 = 0

        foreach ($line in ($text -split "`n")) {
            if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
            if (-not $inFence -and $line -match '^# ') { $h1++ }
        }

        if ($h1 -gt 1) {
            $multiH1 += $file
        }

        $needsFrontmatter = ($file -match '[\\/]agents[\\/]') -or ($file -match '[\\/]prompts[\\/]') -or ($file -match '[\\/]skills[\\/]') -or ($file -match 'project\.instructions\.md$')

        if ($needsFrontmatter -and -not ($text -match '^---\n[\s\S]*?\n---\n')) {
            $badFrontmatter += $file
        }
    }

    Assert-True ($files.Count -gt 0) "$Label - generated markdown files exist ($($files.Count))"
    Assert-True ($bom.Count -eq 0) "$Label - no byte-order marks"
    Assert-True ($crlf.Count -eq 0) "$Label - LF line endings"
    Assert-True ($multiH1.Count -eq 0) "$Label - at most one top-level heading per file $(if ($multiH1) { $multiH1 -join ', ' })"
    Assert-True ($badFrontmatter.Count -eq 0) "$Label - frontmatter present $(if ($badFrontmatter) { $badFrontmatter -join ', ' })"
}

$CopilotFiles = @(
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
    ".github/prompts/review.prompt.md",
    ".github/prompts/investigate.prompt.md",
    ".github/prompts/test.prompt.md",
    ".github/prompts/parity.prompt.md",
    ".github/prompts/bootstrap-knowledge.prompt.md"
)

$ClaudeFiles = @(
    ".claude/rules/ai-engineering.md",
    ".claude/agents/orchestrator.md",
    ".claude/agents/planner.md",
    ".claude/agents/developer.md",
    ".claude/agents/tester.md",
    ".claude/agents/reviewer.md",
    ".claude/agents/legacy-parity.md",
    ".claude/skills/feature/SKILL.md",
    ".claude/skills/bug-fix/SKILL.md",
    ".claude/skills/migration/SKILL.md",
    ".claude/skills/code-review/SKILL.md",
    ".claude/skills/investigate/SKILL.md",
    ".claude/skills/test/SKILL.md",
    ".claude/skills/parity/SKILL.md",
    ".claude/skills/bootstrap-knowledge/SKILL.md"
)

function Test-AllExist {
    param([string]$Repo, [string[]]$Files)
    foreach ($f in $Files) { if (-not (Test-RepoFile $Repo $f)) { return $false } }
    return $true
}

function Test-NoneExist {
    param([string]$Repo, [string[]]$Files)
    foreach ($f in $Files) { if (Test-RepoFile $Repo $f) { return $false } }
    return $true
}

# ===========================================================================
# Setup
# ===========================================================================

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required to run the installer tests."
}

Write-Host "Framework: $FrameworkSource"
Write-Host "Temp:      $TempRoot"
Write-Host "Shell:     $PowerShellExe ($($PSVersionTable.PSVersion))"

New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

# A committed copy of the framework, so the manifest records a clean commit.
$Framework = Join-Path $TempRoot "framework"
New-Item -ItemType Directory -Path $Framework -Force | Out-Null

foreach ($item in @("standards", "agents", "workflows", "prompts", "adapters", "scripts")) {
    Copy-Item -LiteralPath (Join-Path $FrameworkSource $item) -Destination $Framework -Recurse
}

Invoke-Git $Framework @("init", "-q")
Invoke-Git $Framework @("add", "-A")
Invoke-Git $Framework @("-c", "user.email=test@example.com", "-c", "user.name=test", "commit", "-q", "-m", "test")

try {

    # -----------------------------------------------------------------------
    Write-TestHeader "GitHub Copilot: fresh install (default harness)"

    $copilot = New-GitRepository "copilot"
    $result = Invoke-Installer $Framework $copilot

    Assert-True ($result.ExitCode -eq 0) "installer succeeds"
    Assert-True (Test-AllExist $copilot $CopilotFiles) "all Copilot files generated"
    Assert-True (Test-RepoFile $copilot ".github/instructions/project.instructions.md") "project-owned instructions scaffolded"
    Assert-True (Test-RepoFile $copilot ".ai/project.md") ".ai/ scaffolded"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $copilot ".claude"))) "no Claude files"
    Assert-True ((Read-Manifest $copilot).harness -eq "github-copilot") "manifest records github-copilot"
    Assert-True ((Read-RepoFile $copilot ".ai/framework-manifest.json").StartsWith("{`n  `"framework`": `"ai-engineering-framework`",`n  `"manifestVersion`": 2,`n")) "manifest uses the stable JSON format"
    Assert-FileFormat $copilot "Copilot"

    $orchestrator = Read-RepoFile $copilot ".github/agents/orchestrator.agent.md"
    Assert-True ($orchestrator.Contains("tools: ['read', 'search', 'edit', 'execute', 'agent', 'todo']")) "orchestrator Copilot tools (no harness-specific extras)"
    Assert-True ($orchestrator.Contains("agents: ['planner', 'developer', 'tester', 'reviewer', 'legacy-parity']")) "orchestrator subagent list"
    Assert-True ((Read-RepoFile $copilot ".github/agents/reviewer.agent.md").Contains("tools: ['read', 'search']")) "reviewer is read-only"
    Assert-True ((Read-RepoFile $copilot ".github/agents/reviewer.agent.md").Contains("## Project Knowledge Standards")) "Copilot agents include the shared standard"

    # -----------------------------------------------------------------------
    Write-TestHeader "GitHub Copilot: idempotent re-run"

    $result = Invoke-Installer $Framework $copilot @("-Force")
    Assert-True ($result.ExitCode -eq 0) "installer succeeds"
    Assert-True (-not ($result.Output -match "Generated:|Written:|Removed")) "no files written on identical re-run"

    # -----------------------------------------------------------------------
    Write-TestHeader "Claude Code: fresh install"

    $claude = New-GitRepository "claude"
    $result = Invoke-Installer $Framework $claude @("-Harness", "Claude")

    Assert-True ($result.ExitCode -eq 0) "installer succeeds"
    Assert-True (Test-AllExist $claude $ClaudeFiles) "all Claude files generated"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $claude ".github"))) "no Copilot files"
    Assert-True (-not (Test-RepoFile $claude "CLAUDE.md")) "CLAUDE.md not created"
    Assert-True ((Read-Manifest $claude).harness -eq "claude-code") "manifest records claude-code"
    Assert-FileFormat $claude "Claude"

    $orchestrator = Read-RepoFile $claude ".claude/agents/orchestrator.md"
    Assert-True ($orchestrator.Contains("name: orchestrator")) "agent has name"
    Assert-True ($orchestrator.Contains("Agent(planner, developer, tester, reviewer, legacy-parity)")) "orchestrator subagent allowlist"
    Assert-True ($orchestrator.Contains("AskUserQuestion")) "orchestrator can ask the user"

    $reviewer = Read-RepoFile $claude ".claude/agents/reviewer.md"
    Assert-True ($reviewer.Contains("tools: Read, Grep, Glob`n")) "reviewer is read-only"
    Assert-True ($reviewer.Contains("## Code Review Standards")) "reviewer includes its role standard"
    Assert-True (-not $reviewer.Contains("## Project Knowledge Standards")) "shared standard delivered via rules, not duplicated"
    Assert-True ((Read-RepoFile $claude ".claude/rules/ai-engineering.md").Contains("## Project Knowledge Standards")) "rules include the shared standard"

    $review = Read-RepoFile $claude ".claude/skills/code-review/SKILL.md"
    Assert-True ($review.Contains("context: fork") -and $review.Contains("agent: reviewer")) "/code-review runs in the reviewer"
    Assert-True ($review.Contains("!``git diff --no-color``")) "/code-review injects the working tree diff"
    Assert-True ($review.Contains("allowed-tools: Bash(git status *), Bash(git diff *)")) "/code-review pre-approves only git status/diff"

    $feature = Read-RepoFile $claude ".claude/skills/feature/SKILL.md"
    Assert-True (-not $feature.Contains("context: fork")) "/feature runs in the main conversation"
    Assert-True ($feature.Contains("disable-model-invocation: true")) "/feature is explicit-only"
    Assert-True ($feature.Contains('$ARGUMENTS')) "/feature receives the user's request"

    # -----------------------------------------------------------------------
    Write-TestHeader "Claude Code: harness omitted uses the recorded harness"

    $result = Invoke-Installer $Framework $claude @("-Force")
    Assert-True ($result.ExitCode -eq 0) "installer succeeds"
    Assert-True ($result.Output -match "Harness:\s+Claude Code") "Claude Code selected from manifest"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $claude ".github"))) "Copilot not installed"
    Assert-True (-not ($result.Output -match "Generated:|Written:")) "no files written on identical re-run"

    # -----------------------------------------------------------------------
    Write-TestHeader "Existing CLAUDE.md and non-framework files"

    $custom = New-GitRepository "claude-custom"
    [System.IO.File]::WriteAllText((Join-Path $custom "CLAUDE.md"), "# Team instructions`n")
    New-Item -ItemType Directory -Path (Join-Path $custom ".claude/agents") -Force | Out-Null
    [System.IO.File]::WriteAllText((Get-RepoFile $custom ".claude/agents/reviewer.md"), "team reviewer`n")

    $result = Invoke-Installer $Framework $custom @("-Harness", "Claude")
    Assert-True ($result.ExitCode -eq 0) "installer succeeds"
    Assert-True ((Read-RepoFile $custom ".claude/agents/reviewer.md") -eq "team reviewer`n") "existing file kept without -Force"

    $result = Invoke-Installer $Framework $custom @("-Harness", "Claude", "-Force", "-DryRun")
    Assert-True ($result.Output -match "was not created by the framework") "warns before overwriting a non-framework file"
    Assert-True ((Read-RepoFile $custom "CLAUDE.md") -eq "# Team instructions`n") "CLAUDE.md untouched"

    # -----------------------------------------------------------------------
    Write-TestHeader "Switching harness"

    $switch = New-GitRepository "switch"
    Invoke-Installer $Framework $switch @("-Harness", "Claude") | Out-Null

    $result = Invoke-Installer $Framework $switch @("-Harness", "GitHubCopilot")
    Assert-True ($result.ExitCode -ne 0) "switch without -Force is refused"
    Assert-True ($result.Output -match "Only one harness can be installed at a time") "refusal explains one harness per repository"
    Assert-True (Test-NoneExist $switch $CopilotFiles) "nothing installed after refusal"

    $result = Invoke-Installer $Framework $switch @("-Harness", "GitHubCopilot", "-Force", "-DryRun")
    Assert-True ($result.ExitCode -eq 0) "dry-run switch succeeds"
    Assert-True ((Test-AllExist $switch $ClaudeFiles) -and (Test-NoneExist $switch $CopilotFiles)) "dry run changes nothing"

    # A locally modified Claude file must survive the switch.
    $modified = Get-RepoFile $switch ".claude/agents/tester.md"
    [System.IO.File]::AppendAllText($modified, "`nlocal change`n")

    $result = Invoke-Installer $Framework $switch @("-Harness", "GitHubCopilot", "-Force")
    Assert-True ($result.ExitCode -eq 0) "switch with -Force succeeds"
    Assert-True (Test-AllExist $switch $CopilotFiles) "Copilot files installed"
    Assert-True (Test-NoneExist $switch ($ClaudeFiles | Where-Object { $_ -ne ".claude/agents/tester.md" })) "unmodified Claude files removed"
    Assert-True (Test-RepoFile $switch ".claude/agents/tester.md") "modified Claude file kept"
    Assert-True ($result.Output -match "modified after installation") "kept file reported"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $switch ".claude/skills"))) "empty skill directories removed"
    Assert-True (Test-RepoFile $switch ".ai/project.md") ".ai/ preserved"
    Assert-True ((Read-Manifest $switch).harness -eq "github-copilot") "manifest records the new harness"

    # Switch back.
    $result = Invoke-Installer $Framework $switch @("-Harness", "Claude", "-Force")
    Assert-True ($result.ExitCode -eq 0) "switch back succeeds"
    Assert-True (Test-NoneExist $switch $CopilotFiles) "Copilot generated files removed"
    Assert-True (Test-RepoFile $switch ".github/instructions/project.instructions.md") "Copilot project-owned file kept"

    # -----------------------------------------------------------------------
    Write-TestHeader "Stale generated files"

    $stale = New-GitRepository "stale"
    Invoke-Installer $Framework $stale | Out-Null

    $oldPrompt = Get-RepoFile $stale ".github/prompts/old.prompt.md"
    Copy-Item -LiteralPath (Get-RepoFile $stale ".github/prompts/test.prompt.md") -Destination $oldPrompt

    $manifestPath = Get-RepoFile $stale ".ai/framework-manifest.json"
    $manifest = Read-Manifest $stale
    $testEntry = $manifest.generated | Where-Object { $_.path -eq ".github/prompts/test.prompt.md" }
    $manifest.generated = @($manifest.generated) + [pscustomobject]@{ path = ".github/prompts/old.prompt.md"; sha256 = $testEntry.sha256 }
    [System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 10))

    $result = Invoke-Installer $Framework $stale
    Assert-True ((Test-Path -LiteralPath $oldPrompt) -and ($result.Output -match "Run with -Force to remove")) "stale file reported without -Force"

    $result = Invoke-Installer $Framework $stale @("-Force")
    Assert-True (-not (Test-Path -LiteralPath $oldPrompt)) "stale file removed with -Force"

    # -----------------------------------------------------------------------
    Write-TestHeader "Validation"

    $result = Invoke-Installer $Framework (Join-Path $copilot ".github")
    Assert-True (($result.ExitCode -ne 0) -and ($result.Output -match "root of a Git repository")) "subdirectory target refused"

    $result = Invoke-Installer $Framework $Framework
    Assert-True (($result.ExitCode -ne 0) -and ($result.Output -match "cannot be the framework repository")) "framework repository refused as target"

    $orphan = Join-Path $Framework "standards/orphan.md"
    [System.IO.File]::WriteAllText($orphan, "# Orphan`n")
    $result = Invoke-Installer $Framework (New-GitRepository "orphan") @("-DryRun")
    Assert-True (($result.ExitCode -ne 0) -and ($result.Output -match "not delivered")) "undelivered standard refused"
    Remove-Item -LiteralPath $orphan
}
finally {
    if ($KeepTemp) {
        Write-Host ""
        Write-Host "Temporary files kept: $TempRoot"
    }
    else {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Passed: $script:Passed  Failed: $script:Failed" -ForegroundColor $(if ($script:Failed -eq 0) { "Green" } else { "Red" })

if ($script:Failed -gt 0) {
    exit 1
}
