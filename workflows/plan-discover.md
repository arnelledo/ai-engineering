# Workflow: Plan Discovery

Apply the Project Planning Standards. This workflow writes planning documents only, never application code. Source documents and legacy code are read-only.

If `.ai/plan/` already exists, do not regenerate it. Report its state and continue from what is missing, or suggest `/plan-add-source` for new material.

## Phase 1 — Register Sources

Identify the sources named in the request. Create `.ai/plan/sources.md`.

Determine the mode: modernization if any source is legacy code or a legacy database, otherwise new development. State the mode.

If a named source cannot be read, report it and do not treat it as reviewed.

Read `.ai/project.md` for constraints already decided.

## Phase 2 — Digest Documents

Use the Planner role.

For each non-code source, propose `discovery/sources/SRC-NN.md`: what it covers, its version and date, how reliable it appears, and which features it affects.

## Phase 3 — Build the Inventory

Use the Planner role.

Propose:

- `discovery/inventory.md`: features `F-NN`, starting at `F-01`, each with the sources that support it;
- `discovery/data-model.md`: legacy tables and who reads or writes them, or a proposed domain model for new development;
- `discovery/traceability.md`: sources to features.

Record what is unclear as `Q-NNN` in `questions.md`, with the sources and affected features.

For new development, walk each feature through the completeness checklist in the Requirements Quality Standards. Each gap becomes a question.

For modernization, also compare documentation with actual behavior. Each disagreement becomes a question.

Record the Planner's output yourself. Create `.ai/plan/README.md` with the status of each feature.

## Phase 4 — Review the Inventory

Use the Requirements Analyst to review the inventory.

Apply findings that the sources can answer and add the rest to `questions.md`. Run at most two review rounds. Record the result in `discovery/inventory-review.md`.

## Phase 5 — Approval A

Stop. Report:

- the mode;
- the features found;
- the open questions, most consequential first;
- what the analyst questioned and how it was resolved;
- sources that could not be read.

Ask the human to confirm the inventory and answer the questions. Do not start the roadmap in this run.
