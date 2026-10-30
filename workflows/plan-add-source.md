# Workflow: Plan Add Source

Apply the Project Planning Standards. This workflow writes planning documents only, never application code. Do not change any approved requirement in this run.

## Phase 1 — Register

Add the source to `.ai/plan/sources.md` with the next `SRC-NN`. If it cannot be read, report it and stop.

If it is the first legacy source, state that the project now follows modernization rules.

## Phase 2 — Analyze Impact

Use the Planner role.

Propose `discovery/sources/SRC-NN.md` when the source is not code, and identify:

- requirements it confirms, which may upgrade their coverage;
- requirements it contradicts;
- behavior it describes that no requirement covers;
- features it affects, including any new feature.

Use the Requirements Analyst to check the impact when it affects approved requirements.

## Phase 3 — Record

- Mark each contradicted requirement as needing re-verification, citing the source.
- Add a question for each contradiction and each uncovered behavior.
- Remove `READY` from each affected feature, and update `.ai/plan/README.md`.
- Update `discovery/traceability.md`.

## Phase 4 — Stop

Report the affected features and requirements, the new questions, tasks that can no longer proceed, and any task already `DONE` whose behavior may now be wrong.

Do not change requirements until the human decides.
