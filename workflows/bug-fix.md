\# Workflow: Bug Fix



\## Phase 1 — Reproduce / Understand



Capture:



\- observed behavior;

\- expected behavior;

\- reproduction conditions;

\- relevant logs/errors.



Do not change code yet.



\## Phase 2 — Investigate



Trace the failing execution path.



Form hypotheses.



Validate hypotheses against code, tests, logs, and persistence behavior.



Do not implement the first plausible fix without identifying the root cause.



\## Phase 3 — Regression Test



When practical, create a test that demonstrates the defect.



Confirm it fails for the correct reason.



\## Phase 4 — Implement



Make the smallest correction addressing the root cause.



Avoid unrelated refactoring.



\## Phase 5 — Verify



Run:



\- regression test;

\- related tests;

\- build;

\- relevant integration verification.



\## Phase 6 — Review



Review the final diff for:



\- regression risk;

\- unintended behavior changes;

\- persistence effects;

\- missing edge cases.



\## Completion Report



\### Root Cause



\### Fix



\### Regression Test



\### Verification



\### Remaining Risk

