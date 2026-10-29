# Installer Reference

Detailed behavior of `scripts/install.ps1`. For everyday use, see the Quick Start in the [README](../README.md).

## Parameters

| Parameter | Purpose |
|---|---|
| `-TargetRepo` | Root of the application's Git repository (required) |
| `-Harness` | `GitHubCopilot` or `Claude`. When omitted, the harness recorded in the manifest, or `GitHubCopilot` |
| `-DryRun` | Report what would change without writing anything |
| `-Force` | Replace existing framework-generated files, remove stale files, and allow switching harness |

The same installer is used for first installation and for later framework updates.

## Platforms

The installer runs on Windows PowerShell 5.1 and on PowerShell 7 on Windows, macOS, and Linux. On macOS, install PowerShell 7 with `brew install powershell`, then run `./scripts/install.ps1` (or `pwsh ./scripts/install.ps1`) with the same parameters.

Generated files and the manifest are byte-identical on every platform and PowerShell version, so team members on different operating systems can update the same repository without spurious diffs. The manifest is written by the installer's own JSON writer rather than `ConvertTo-Json`, whose formatting differs between Windows PowerShell 5.1 and PowerShell 7. A manifest written by an earlier installer is reformatted once on the next `-Force` run.

## Target Repository

The target must be the root of a Git repository. Copilot and Claude Code read their configuration only from the repository root, so the installer refuses a subdirectory and reports the actual root. It also refuses the framework repository itself.

All files are written as UTF-8 without a byte-order mark, with LF line endings.

## One Harness per Repository

- When `-Harness` is omitted, the installer updates the harness recorded in `.ai/framework-manifest.json`, or installs GitHub Copilot when there is no manifest.
- Installing a different harness than the recorded one requires `-Force`. The previous harness's unmodified generated files are removed with the same safety rules as stale-file cleanup. Locally modified files are kept and reported. `.ai/` and project-owned files are never removed.

Preview a switch first:

    .\scripts\install.ps1 -TargetRepo "C:\path\to\application" -Harness Claude -DryRun -Force

## File Ownership

Framework-owned files are generated and may be replaced with `-Force`:

- GitHub Copilot: `.github/copilot-instructions.md`, `.github/agents/*`, `.github/prompts/*`
- Claude Code: `.claude/rules/ai-engineering.md`, `.claude/agents/*`, `.claude/skills/*`
- `.ai/framework-manifest.json`

Project-owned files are never overwritten, even with `-Force`:

- `.ai/` (every scaffolded file)
- `.github/instructions/project.instructions.md` (scaffolded once for GitHub Copilot)
- `CLAUDE.md` and `.claude/settings.json` (never touched)

## What `-Force` Does

Without `-Force`, existing generated files are skipped and reported.

With `-Force`, the installer replaces generated files whose content changed, and warns first when it is about to overwrite:

- a generated file that was modified after the last installation;
- an existing file the framework did not create (not recorded in the manifest).

Run with `-DryRun -Force` to see these warnings before applying. Files whose content is unchanged are not rewritten.

## Framework Manifest

`.ai/framework-manifest.json` records:

- the installed harness (`github-copilot` or `claude-code`);
- the framework commit, and whether the framework repository had uncommitted changes;
- the path and content hash of every generated file;
- the project-owned files the installer scaffolds.

It has no timestamp, so it changes only when the framework commit or the generated content changes. Line-ending conversion by Git is not treated as a modification.

Commit the framework repository before installing; otherwise the installer warns that the recorded commit does not fully describe the installed content.

## Stale Generated Files

When a framework agent or command is renamed or removed, or when switching harness, previously generated files become stale.

- Without `-Force`, stale files are reported.
- With `-Force`, stale files under the harness's managed paths are removed, but only when their content still matches the recorded hash. Directories left empty are removed.
- Stale files that were modified locally, or recorded by an older installer without hashes, are kept and reported for manual review.

## Validation

Before generating anything, the installer verifies that:

- every agent, command, and standard referenced by `scripts/framework.psd1` exists;
- every agent declares an explicit tool list, and subagent and command references point to existing agents;
- every file in `standards/` is delivered to an agent or to the repository-wide instructions.
