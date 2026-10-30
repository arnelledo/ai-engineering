# Workflow: Plan Next

Apply the Project Planning Standards. This workflow writes planning documents only, never application code.

Each run produces exactly one step for one feature, then stops for human approval. Do not produce several steps in one run.

## Phase 1 — Determine the Step

Use the feature named in the request. If none is named, use the first feature in roadmap order that is not `READY`.

Inspect the feature's documents and take the first step that applies.

For `F-00`:

1. no ADR: propose the target architecture ADR (approval C);
2. ADR not accepted: stop and ask for the decision;
3. no `TASKS.md`: propose the tasks (approval E);
4. no `TEST_PLAN.md`: propose the test plan (approval E);
5. otherwise: evaluate Ready.

For any other feature:

1. the roadmap is not approved or `F-00` has no accepted ADR: stop and say so;
2. no `REQUIREMENTS.md`: extract requirements (approval D);
3. any requirement is `PROPOSED`, or a question affecting the feature is open: stop and list what needs a decision;
4. no `SPEC.md`: propose the spec (approval E);
5. no `TASKS.md`: propose the tasks (approval E);
6. no `TEST_PLAN.md`: propose the test plan (approval E);
7. otherwise: review the package and evaluate Ready.

If a document awaits approval, stop and ask for it instead of continuing. Treat a human's statement in this conversation, or a human's committed edit, as the decision, and record it.

## Phase 2 — Produce

Use the Planner role. Provide the step, the relevant `.ai/plan/` paths, and the accepted ADRs.

- **Architecture:** ADR from discovery evidence and project constraints, as defined under Phase 0: Foundation.
- **Requirements:** feature `README.md` and `REQUIREMENTS.md`, with evidence, coverage, and an acceptance criterion for each.
- **Spec:** target behavior, contracts, errors, and entities, derived only from `APPROVED` and `CHANGE` requirements and placed according to the ADR.
- **Tasks:** following Task Scope. For `F-00`, derived from the ADR.
- **Test plan:** scenarios per requirement, from acceptance criteria and, in modernization, legacy evidence.

Record the Planner's output yourself. Add new questions to `questions.md`.

## Phase 3 — Review

Use the Requirements Analyst when producing requirements, and when reviewing the complete package. Provide the paths and the sources, not your conclusions.

Apply findings that the sources can answer and turn the rest into questions. Run at most two review rounds. Record the rounds in `REVIEW.md`.

## Phase 4 — Ready

When the package review verdict is `READY` and the human has approved the last document, mark the feature `READY` in its `README.md` and update `.ai/plan/README.md`.

## Phase 5 — Stop

Report what was produced, what the analyst questioned and how it was resolved, the coverage counts, the new questions, and the exact decision needed.

Do not continue to the next step in this run.
