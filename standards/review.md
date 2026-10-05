\# Code Review Standards



\## Purpose



Code review exists to identify meaningful risk before changes are accepted.



Do not manufacture findings to appear thorough.



Do not recommend changes solely because another implementation style is preferred.



\## Review Priorities



\### Critical



Issues that may cause:



\- data corruption;

\- serious security vulnerabilities;

\- incorrect financial/business behavior;

\- destructive operations;

\- major race conditions;

\- severe transaction failures.



\### High



Issues such as:



\- incorrect business logic;

\- significant regression risk;

\- missing authorization;

\- broken transaction behavior;

\- incorrect persistence behavior;

\- architecture violations with real consequences;

\- important legacy parity differences.



\### Medium



Issues such as:



\- insufficient error handling;

\- meaningful performance problems;

\- missing important tests;

\- maintainability problems likely to cause defects.



\### Low



Issues such as:



\- naming;

\- readability;

\- minor duplication;

\- style inconsistencies.



Avoid reporting purely cosmetic issues unless specifically requested.



\## Review Method



Review the change in context.



Inspect:



\- requirement;

\- changed code;

\- callers;

\- tests;

\- persistence effects;

\- error paths;

\- relevant existing implementation.



Review the final diff, not only individual files.



\## Required Finding Format



Every finding should include:



\*\*Severity\*\*



\*\*Location\*\*



\*\*Problem\*\*



\*\*Failure Scenario / Impact\*\*



\*\*Recommended Correction\*\*



\## Evidence



Do not present speculation as a defect.



If evidence is insufficient, classify the observation as a question or risk.



\## Scope



Identify unrelated changes.



Flag unnecessary refactoring when it increases review or regression risk.



\## Tests



Determine whether tests prove the requested behavior.



Check for missing:



\- regression scenarios;

\- negative cases;

\- persistence validation;

\- duplicate/retry behavior;

\- concurrency scenarios when applicable.



\## Review Outcome



Conclude with one of:



\- APPROVE

\- APPROVE WITH NON-BLOCKING COMMENTS

\- CHANGES REQUIRED

\- INSUFFICIENT INFORMATION



Explain blocking findings separately from optional improvements.

