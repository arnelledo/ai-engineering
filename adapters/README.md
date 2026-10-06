# Harness Adapters

This directory contains harness-specific adapter logic.

Canonical engineering instructions must not be duplicated here.

The source of truth lives in:

- `standards/`
- `agents/`
- `workflows/`
- `prompts/`
- `scripts/framework.psd1` (harness-neutral metadata)

Adapters should contain only harness-specific metadata, templates, transformations, or deployment logic required to convert canonical framework definitions into a format understood by a particular AI harness.

## Available Adapters

| Adapter | `-Harness` value | Manifest id | Generates |
|---|---|---|---|
| `github-copilot/adapter.ps1` | `GitHubCopilot` | `github-copilot` | `.github/copilot-instructions.md`, `.github/agents/`, `.github/prompts/` |
| `claude-code/adapter.ps1` | `Claude` | `claude-code` | `.claude/rules/ai-engineering.md`, `.claude/agents/`, `.claude/skills/` |

A repository has one harness installed at a time.

## Adapter Contract

`scripts/install.ps1` dot-sources every `adapters/*/adapter.ps1`. Each adapter registers itself:

```powershell
$HarnessAdapters["<-Harness value>"] = @{
    Id              = "<manifest id>"
    DisplayName     = "<name shown to users>"
    InstallFunction = "<function that generates the harness files>"
    ManagedPrefixes = @("<repository-relative paths cleanup may remove from>")
    ProjectOwned    = @("<project-owned files the adapter scaffolds>")
    NextSteps       = @("<steps printed after installation>")
}
```

The install function:

- reads agents, commands, and standards from `$Framework` (`scripts/framework.psd1`) and the canonical directories;
- writes framework-owned files only through `Write-GeneratedFile`, so they are hashed, recorded in the manifest, and protected by the `-Force` rules;
- writes project-owned files only through `Write-ScaffoldFile`, so they are never overwritten;
- translates the harness-neutral tool capabilities (read, search, edit, execute, agent, web, todo, ask) into the harness's tool names.

Add a `-Harness` value to the `ValidateSet` in `scripts/install.ps1` and cover the new adapter in `tests/Invoke-InstallerTests.ps1`.
