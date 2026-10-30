# AI Engineering Framework

A reusable, harness-independent framework for AI-assisted software engineering.

The objective is to improve engineering quality while reducing implementation time by giving AI coding tools a disciplined engineering process rather than treating them as autocomplete.

## Core Model

| Concern | Defines | Stored in |
|---|---|---|
| Engineering framework | How AI should work | This repository: `standards/`, `agents/`, `workflows/`, `prompts/` |
| Persistent project knowledge | How a specific application works | The application repository: `.ai/` |
| Active task context | Working context that survives sessions and agents | The application repository: `.ai/tasks/` |

For non-trivial work the framework follows:

Understand → Investigate → Plan → Implement → Test → Review → Correct → Verify → Human Approval

Legacy modernization adds explicit parity analysis before implementation.

Larger projects can first turn documents, tickets, and legacy code into reviewed requirements and a plan by phase and feature. See [docs/planning.md](docs/planning.md).

Consequential operations (production deployment, destructive database operations, pushing or merging, infrastructure changes) always require explicit human authorization. See `standards/human-control.md`.

## Quick Start

Choose one harness per application repository: `GitHubCopilot` or `Claude`.

Preview, then install:

    .\scripts\install.ps1 -TargetRepo "C:\path\to\application" -Harness GitHubCopilot -DryRun
    .\scripts\install.ps1 -TargetRepo "C:\path\to\application" -Harness GitHubCopilot

Use `-Harness Claude` for Claude Code. Do not use `-Force` for a first installation.

On macOS or Linux, install PowerShell 7 (`brew install powershell` on macOS) and run the same commands with forward slashes:

    ./scripts/install.ps1 -TargetRepo ~/src/application -Harness Claude -DryRun
    ./scripts/install.ps1 -TargetRepo ~/src/application -Harness Claude

If the script is not executable in your checkout, run it as `pwsh ./scripts/install.ps1 ...`. The installer requires Windows PowerShell 5.1 or PowerShell 7 and Git (recommended); its output is identical on every platform.

Then bootstrap the project knowledge:

- **GitHub Copilot:** in VS Code Copilot Chat, select the Orchestrator agent and run `/bootstrap-knowledge`.
- **Claude Code:** run `claude --agent orchestrator` (or open the Claude Code panel) and run `/bootstrap-knowledge`.

Review the generated `.ai/` knowledge, correct unsupported claims, and commit the generated files and `.ai/` with the application.

### Updating After Framework Changes

Framework change → `-DryRun -Force` → Review → `-Force` → Review Git diff

    .\scripts\install.ps1 -TargetRepo "C:\path\to\application" -DryRun -Force
    .\scripts\install.ps1 -TargetRepo "C:\path\to\application" -Force

When `-Harness` is omitted, the installer updates the harness recorded in `.ai/framework-manifest.json` (or installs GitHub Copilot when there is none). Changes made only to `.ai/` knowledge never require running the installer.

Installing a different harness than the recorded one requires `-Force`; the previous harness's unmodified generated files are removed. See [Installer Reference](docs/installer.md) for `-Force`, the manifest, harness switching, and stale-file cleanup.

## Repository Structure

```text
ai-engineering/
├── standards/     engineering standards (canonical)
├── agents/        specialized agent roles (canonical)
├── workflows/     end-to-end engineering workflows (canonical)
├── prompts/       specialist commands (canonical)
├── scripts/
│   ├── install.ps1       installer entry point
│   ├── framework.psd1    harness-neutral metadata
│   └── lib/              shared installer code and the .ai/ scaffold
├── adapters/      one adapter per harness (GitHub Copilot, Claude Code)
├── docs/          installer reference
└── tests/         installer test suite
```

## How It Works

### Source of Truth

`standards/`, `agents/`, `workflows/`, and `prompts/` are the source of truth. All engineering instruction text lives there.

`scripts/framework.psd1` describes the framework in harness-neutral terms: each agent's description, tool capabilities, subagents and role-specific standards; each command's source, agent and argument hint; and which standards form the repository-wide instructions.

An adapter translates the canonical framework into a harness's native format:

Canonical framework → `install.ps1` → adapter → application repository

| Canonical source | GitHub Copilot | Claude Code |
|---|---|---|
| Repository-wide standards | `.github/copilot-instructions.md` | `.claude/rules/ai-engineering.md` |
| `agents/` | `.github/agents/*.agent.md` | `.claude/agents/*.md` |
| `workflows/`, `prompts/` | `.github/prompts/*.prompt.md` | `.claude/skills/<command>/SKILL.md` |
| Project-owned instructions | `.github/instructions/project.instructions.md` (scaffolded once) | `CLAUDE.md` (never created or modified) |
| Project knowledge | `.ai/` (scaffolded once) | `.ai/` (scaffolded once) |

Adapters contain only harness-specific metadata, templates, and deployment logic, never copies of engineering instructions. See [adapters/README.md](adapters/README.md).

### How Standards Are Delivered

The repository-wide instructions are assembled from `development.md`, `security.md`, `project-knowledge.md`, and `human-control.md`, in that order.

Role-specific standards are appended to the agents that need them: `testing.md` to the tester, `review.md` to the reviewer, `legacy-parity.md` to the legacy parity analyst, `requirements-quality.md` to the requirements analyst, and `planning.md` to the orchestrator, planner, legacy parity analyst, and requirements analyst.

`project-knowledge.md` must reach every agent. GitHub Copilot appends it to every agent, because Copilot subagents may not receive the repository-wide instructions. Claude Code loads `.claude/rules/` into every subagent, so it is not duplicated there.

Agent files contain only role-specific guidance and refer to the appended standards. Severity levels, finding format, review verdicts, test scenarios, and parity classifications are defined only in `standards/`.

The installer refuses to run if a standard is not delivered anywhere. When adding a standard, add it to `InstructionStandards` or to an agent's `Standards` list in `scripts/framework.psd1`.

## Agents

| Agent | Role | Tool capabilities | Modifies files |
|---|---|---|---|
| `orchestrator` | Classifies the task, selects the workflow, delegates to specialists, owns task documents and verification | read, search, edit, execute, agent, todo, ask | Yes |
| `planner` | Investigates requirements, execution flow, root cause, risks, and implementation strategy | read, search, web | No |
| `developer` | Implements the smallest correct change | read, search, edit, execute, todo | Yes |
| `tester` | Performs adversarial verification and writes tests | read, search, edit, execute, todo | Yes |
| `reviewer` | Independently evaluates correctness, risk, business behavior, architecture, security, and test quality | read, search | No |
| `legacy-parity` | Compares modern behavior against authoritative legacy behavior | read, search | No |
| `requirements-analyst` | Critically reviews extracted features, requirements, and plans against their sources | read, search | No |

Role boundaries are enforced by each harness's tool restrictions, not only by instructions.

Only the Orchestrator can invoke other agents, and only the six specialists. Each specialist runs with its own context and tools, which keeps implementation and review independent. Read-only specialists return proposed updates; the Orchestrator records them under `.ai/tasks/` or `.ai/plan/`.

Each adapter translates the capabilities into harness tool names:

| Capability | GitHub Copilot | Claude Code |
|---|---|---|
| read | `read` | `Read` |
| search | `search` | `Grep`, `Glob` |
| edit | `edit` | `Edit`, `Write`, `NotebookEdit` |
| execute | `execute` | `Bash`, `PowerShell` |
| agent | `agent` + `agents: [...]` | `Agent(<allowed subagents>)` |
| web | `web` | `WebFetch`, `WebSearch` |
| todo | `todo` | `TodoWrite` |
| ask | (not mapped) | `AskUserQuestion` |

## Commands

| Command | Source | Runs as | Purpose |
|---|---|---|---|
| `/feature` | `workflows/feature.md` | orchestrator | Non-trivial feature development |
| `/bug-fix` | `workflows/bug-fix.md` | orchestrator | Root-cause investigation, regression test, fix, review |
| `/migration` | `workflows/migration.md` | orchestrator | Legacy modernization with explicit parity verification |
| `/plan-discover` | `workflows/plan-discover.md` | orchestrator | Register sources, extract and review the feature inventory |
| `/plan-roadmap` | `workflows/plan-roadmap.md` | orchestrator | Propose phases, starting with Foundation |
| `/plan-next` | `workflows/plan-next.md` | orchestrator | Produce and review the next planning document of a feature |
| `/plan-add-source` | `workflows/plan-add-source.md` | orchestrator | Add a late source and flag what it affects |
| `/bootstrap-knowledge` | `prompts/bootstrap-knowledge.md` | orchestrator | Initial, evidence-driven population of `.ai/` |
| `/investigate` | `prompts/investigate.md` | planner | Investigate a problem without modifying code |
| `/test` | `prompts/test.md` | tester | Adversarial testing of an implementation |
| `/parity` | `prompts/parity.md` | legacy-parity | Compare modern and legacy behavior |
| `/review` (Copilot), `/code-review` (Claude Code) | `workflows/code-review.md` | reviewer | Independent review of the current change |

Commands run with the tools of their agent, so `/investigate`, `/parity`, and the review command are read-only.

Bootstrap is intended for initial onboarding. Afterwards, project knowledge should evolve incrementally through normal engineering work.

## GitHub Copilot

Install with `-Harness GitHubCopilot` (the default). The installer generates `.github/copilot-instructions.md`, one `.github/agents/<agent>.agent.md` per agent, and one `.github/prompts/<command>.prompt.md` per command.

`.github/copilot-instructions.md` is framework-owned and replaced on every update. Repository-specific Copilot rules belong in `.github/instructions/project.instructions.md`, which the installer creates once (`applyTo: "**"`) and never overwrites. Keep it short; it applies to every request.

### Requirements

- VS Code with GitHub Copilot Chat on the current stable release. Custom agents require VS Code 1.106 or later; subagent delegation and the prompt-file `agent` field are newer, so keep both up to date.
- Windows PowerShell 5.1 or PowerShell 7 (Windows, macOS, or Linux), and Git (recommended).

### Where Each File Works

| File | VS Code | Copilot coding agent on GitHub.com |
|---|---|---|
| `.github/copilot-instructions.md` | Yes | Yes |
| `.github/instructions/*.instructions.md` | Yes | Yes |
| `.github/agents/*.agent.md` | Yes | Yes; `argument-hint` and `handoffs` are ignored |
| `.github/prompts/*.prompt.md` | Yes | No |

Slash commands are VS Code features. On GitHub.com, select the custom agent and describe the task instead. To let the coding agent build and run tests on GitHub.com, add a `copilot-setup-steps.yml` workflow; see [adapters/github-copilot/README.md](adapters/github-copilot/README.md).

## Claude Code

Install with `-Harness Claude`. The installer generates `.claude/rules/ai-engineering.md`, one `.claude/agents/<agent>.md` per agent, and one `.claude/skills/<command>/SKILL.md` per command.

### Instructions

The repository-wide standards go to `.claude/rules/ai-engineering.md`, which Claude Code loads in every session and every subagent. The rules file is about 380 lines, so keep `CLAUDE.md` short.

`CLAUDE.md` and `.claude/settings.json` belong to the repository team. The installer never creates or modifies them. It does not create a missing `CLAUDE.md`, because one stops Claude Code from reading an existing `AGENTS.md` by default.

### Starting a Session

    claude --agent orchestrator

Claude Code runs in the terminal, the VS Code Claude Code panel, or the Code tab of the Claude desktop app; all of them use the same `.claude/` files. The workflow commands also tell Claude to follow the Orchestrator role when the session was not started with `--agent`. To make the Orchestrator the default for every session, a team can add `"agent": "orchestrator"` to `.claude/settings.json`.

### Command Behavior

- The orchestrator commands (`/feature`, `/bug-fix`, `/migration`, `/plan-*`, `/bootstrap-knowledge`) run in the main conversation, so the Orchestrator can ask you questions at its human checkpoints.
- The specialist commands run in their subagent (`context: fork`) with that subagent's tool restrictions. A forked subagent does not see the conversation, so describe the task after the command.
- `/code-review` inserts the current `git status` and diffs before it runs, so the read-only reviewer sees the changes without shell access. This needs a local session; injected commands do not run in Cowork or cloud sessions.
- All commands run only when typed (`disable-model-invocation: true`).
- `/code-review` replaces Claude Code's bundled `/code-review` in the repository; the bundled `/review` alias still runs the bundled skill.

### VS Code Copilot Chat

VS Code's Copilot Chat also reads `.claude/agents/` and `.claude/skills/` and translates them. That is still Copilot, not Claude Code, and Claude-specific behavior may not carry over. For a repository used mainly with Copilot Chat, install the GitHub Copilot harness instead.

## Project Knowledge

Application-specific knowledge lives in the application repository, never in this framework:

```text
.ai/
├── project.md         purpose, technology, terminology, verification commands
├── architecture.md    boundaries, dependency direction, constraints
├── business-rules/    durable observable business behavior
├── components/        important components and responsibilities
├── database/          persistence behavior and constraints
├── integrations/      external systems and messaging
├── legacy/            authoritative legacy behavior and parity
├── decisions/         engineering decisions and rationale
├── plan/              requirements and plan, created by /plan-discover when needed
└── tasks/             active task context across sessions and agents
```

The installer scaffolds these files once and never overwrites them, except `plan/`, which it does not create. How agents use, verify, and maintain this knowledge is defined in `standards/project-knowledge.md`. Do not store secrets in framework or project-knowledge documentation.

## Testing the Installer

    .\tests\Invoke-InstallerTests.ps1      # Windows
    ./tests/Invoke-InstallerTests.ps1      # macOS / Linux

Runs the installer end to end against throwaway repositories for both harnesses, including re-runs, harness switching, stale-file cleanup, and validation failures. Requires Git; runs on Windows PowerShell 5.1 and PowerShell 7. Run it after changing the installer, an adapter, or `scripts/framework.psd1`.

The `Installer Tests` GitHub Actions workflow (`.github/workflows/installer-tests.yml`) runs the suite on Windows (Windows PowerShell 5.1 and PowerShell 7), macOS, and Linux for every push and pull request.

## Design Principle

The framework should make AI behave like a disciplined engineering team.

Correctness and evidence are more important than the amount of generated code.
