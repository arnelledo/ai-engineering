# Workflow: Plan Roadmap

Apply the Project Planning Standards. This workflow writes planning documents only, never application code.

## Phase 1 — Check Readiness

Read `.ai/plan/`. If the inventory has not been confirmed by a human, stop and say so.

Open questions do not block the roadmap unless they change which features exist or their order. List those that do.

## Phase 2 — Propose Phases

Use the Planner role.

Propose `roadmap.md`:

- phase `P0`, containing `F-00` Foundation, always first;
- later phases ordered by dependencies, risk, and value;
- the dependencies and exit criteria of each phase;
- for modernization, scope the legacy system does not have, separated as `NEW-NN`, each requiring approval;
- for new development, a priority for each feature, such as MVP or later.

Record the Planner's output yourself, and update `.ai/plan/README.md`.

Have the Requirements Analyst check the scope and priorities when a feature's value or placement is uncertain.

## Phase 3 — Approval B

Stop. Report the phases, the reasoning behind the order, and the decisions needed. Ask the human to approve.

The next step is `/plan-next F-00`.
