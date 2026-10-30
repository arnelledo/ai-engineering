# Project Planning

How to turn documents, tickets, and any legacy system into reviewed requirements and a plan that any developer can execute, feature by feature. The rules are defined in `standards/planning.md` and `standards/requirements-quality.md`.

Use it for work that needs a plan, usually several features or several developers. For a small change with a clear requirement, go directly to `/feature`, `/bug-fix`, or `/migration`.

Planning and implementation are separate:

- **Planning (steps 1–5):** an agent extracts features and requirements with evidence, another reviews them critically, and a person resolves what is unclear and approves. No application code is written.
- **Implementation (step 6):** any developer takes a ready task and implements it in one reviewable pull request.

## One Process, Two Situations

The steps and commands are the same. The difference follows from whether a legacy source is registered:

| | New development | Modernization |
|---|---|---|
| **Sources** | Documents, tickets, notes, designs | The same, plus legacy code and database |
| **Main risk** | Gaps: what nobody wrote down | Differences between what is documented and what the system does |
| **Coverage states** | `CONFIRMED`, `SINGLE-SOURCE`, `CONFLICT`, `ASSUMED` | The same, plus `CODE-ONLY`, `DOC-ONLY` |
| **Data model in discovery** | Proposed domain model | Legacy tables and who uses them |
| **Scope** | Priority: MVP or later | Also `NEW-` for what the legacy system does not do |
| **Implementation** | `/feature T-NN-NN` | `/feature` for Foundation, `/migration T-NN-NN` to compare with legacy |
| **Tests come from** | Acceptance criteria | Acceptance criteria and legacy evidence |

## The Flow

| Step | Command | Who | Produces | Approval |
|---|---|---|---|---|
| 0 | none | You | Sources in `docs-input/`, constraints in `.ai/project.md`, legacy access if any | |
| 1 | `/plan-discover` | Agent, analyst, you | Sources, reviewed inventory, questions | A |
| 2 | `/plan-roadmap` | Agent, you | Phases, Foundation first, and priorities | B |
| 3 | `/plan-next F-00` | Agent, you | Architecture ADR, then Foundation tasks | C, E |
| 4 | `/plan-next F-NN` | Agent, analyst, you | `REQUIREMENTS.md`, `REVIEW.md` | D |
| 5 | `/plan-next F-NN` (three times) | Agent, analyst, you | `SPEC.md`, `TASKS.md`, `TEST_PLAN.md`, then `READY` | E |
| 6 | `/feature T-…` or `/migration T-…` | Any developer | Code, tests, one pull request per task | F |

Each `/plan-next` run produces one step and stops.

### Step 0: Prepare

Once per project:

1. Give read-only access to any legacy code. In Claude Code, add it to `permissions.additionalDirectories` in `.claude/settings.json`, or start with `claude --add-dir <path>`. In VS Code with Copilot, use a multi-root workspace.
2. Put documents in `docs-input/`, exported to PDF or Markdown where possible.
3. Record what is already decided in `.ai/project.md`: required stack, company conventions, and any non-default task size limits.
4. Commit.

### Step 3: Foundation

The roadmap always starts with `F-00`. Before any code, the agent proposes `.ai/decisions/ADR-001-target-architecture.md`. Later tasks are placed and reviewed against it.

The skeleton then goes in its own pull request. It is generated with the stack's official templates and stays thin: only what is needed to build, run tests, and pass a walking skeleton. Packages and abstractions enter with the first task that needs them.

Foundation tasks can proceed while feature requirements are being reviewed, since they do not depend on them.

### Step 6: Implementation

A task does not start unless its feature is `READY`. The agent implements only that task, stops if a gap appears, and stops with a proposed split if the task exceeds the size limit. It then updates the task status and prepares the pull request description, which maps each requirement to code and test, and points out what needs careful review. Commit, push, and pull request remain the developer's decision.

## Requirements Review

The agent that extracts does not review itself. `requirements-analyst` is read-only, works from its own context, and opens the cited sources itself.

| When | Reviews | Main question |
|---|---|---|
| Before approval A | Feature inventory | Is anything missing, unnecessary, or badly divided? |
| Before approval D | `REQUIREMENTS.md` | Is each requirement true, clear, complete, and testable? |
| Before approval E | Whole feature package | Could a developer build this without asking anything? |

Findings are `UNSUPPORTED`, `MISSING`, `AMBIGUOUS`, `UNTESTABLE`, `CONTRADICTION`, or `SCOPE`, each `BLOCKER`, `MAJOR`, or `MINOR`. The Orchestrator applies what the sources can answer and turns the rest into questions. After two rounds, what remains goes to you with the report.

### What Ready Means

No process can guarantee correct requirements: a source can be wrong, and an approved decision can change. What the process guarantees is that nothing reaches a developer without passing the Definition of Ready in `standards/requirements-quality.md`: verified evidence, human approval, a test for each requirement, no open blocking questions or findings.

## Task Size

A task is one complete capability, testable end to end across all layers. One task is one pull request. A coding agent makes writing code cheap; what limits a task is how much a person can review well and how much an agent can do well in one session.

A feature is one task unless a written reason justifies a split: different risk, different reviewer, independent value, or exceeding the limits.

Default limits, configurable in `.ai/project.md`:

- about 15 requirements per task;
- about 1,000 lines of production code per pull request. Tests and generated code do not count.

## When a New Source Appears

    /plan-add-source docs-input/pricing-rules-2022.pdf

The agent registers it, flags the requirements it contradicts, creates questions, and removes `READY` from affected features. Tasks in those features do not proceed until you decide. A changed architecture decision gets a new ADR that supersedes the old one.

## Resulting Structure

```text
.ai/
├── decisions/
│   └── ADR-001-target-architecture.md
└── plan/
    ├── README.md               status map: phases and features
    ├── sources.md              SRC-NN registry
    ├── questions.md            Q-NNN open and answered questions
    ├── roadmap.md              phases, dependencies, exit criteria, scope
    ├── discovery/
    │   ├── sources/SRC-NN.md   one digest per non-code source
    │   ├── inventory.md        features F-NN
    │   ├── inventory-review.md analyst review of the inventory
    │   ├── data-model.md       legacy tables, or proposed domain model
    │   └── traceability.md     source to requirement to task matrix
    └── features/
        ├── F-00-foundation/    README.md, TASKS.md, TEST_PLAN.md
        └── F-03-order-entry/   README.md, REQUIREMENTS.md, REVIEW.md, SPEC.md,
                                TASKS.md, TEST_PLAN.md
```
