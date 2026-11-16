# Workflow: Plan Next

Apply the Project Planning Standards. This workflow writes planning documents only, never application code.

Each run produces one decision for one feature, then stops for human approval.

## Phase 1 — Determine the Step

Use the feature named in the request. If none is named, use the first feature in roadmap order that is not `READY`.

Inspect the feature document and take the first step that applies.

For `F-00`:

1. no ADR: propose the target architecture ADR (approval C);
2. ADR not accepted: stop and ask for the decision;
3. no feature document: propose it, with tasks and their test scenarios (approval D);
4. otherwise: evaluate Ready.

For any other feature:

1. the roadmap is not approved or `F-00` has no accepted ADR: stop and say so;
2. no feature document: propose it complete (approval D);
3. the document awaits a decision: stop and present its decision sheet again;
4. otherwise: evaluate Ready.

Treat a human's statement in this conversation, or a human's committed edit, as the decision, and record it.

## Phase 2 — Produce

Use the Planner role. Provide the step, the relevant `.ai/plan/` paths, and the accepted ADRs.

- **Architecture:** ADR from discovery evidence and project constraints, as defined under Phase 0: Foundation.
- **Feature document:** scope, requirements with evidence, coverage, and test scenarios, contracts, and tasks following Task Scope, all in one document within the budget. For `F-00`, tasks derived from the ADR.

When an open question or an assumption shapes the contracts or tasks, write them for the proposed answer and list the question in the decision sheet.

When a technical unknown could be settled by a short experiment rather than by reading, such as whether an API exists or a schema validates, run it and cite the result as evidence.

Record the Planner's output yourself. Add new questions to `questions.md`.

## Phase 3 — Review

Use the Requirements Analyst once, on the complete feature document. Provide the paths and the sources, not your conclusions.

Apply findings that the sources can answer and turn the rest into questions. Run a second round only when a `BLOCKER` remains after applying the first. Record the verdict and the open findings in the document's Review section.

## Phase 4 — Stop

Set the status to `AWAITING DECISION` and present the decision sheet as defined in the Project Planning Standards. Do not include the document itself or the analyst's report.

When the human decides, record the decisions and approvals. If the Definition of Ready holds, set the status to `READY`.

Do not continue to the next feature in this run.
