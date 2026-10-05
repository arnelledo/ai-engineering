\# Legacy Parity Standards



\## Purpose



Modernization does not automatically mean changing behavior.



When replacing a legacy implementation, preserve observable business behavior unless a behavior change is explicitly required.



\## Source of Truth



Determine which legacy implementation is authoritative.



Do not infer legacy behavior only from documentation if executable legacy code is available.



Inspect actual:



\- control flow;

\- conditions;

\- database operations;

\- calculations;

\- defaults;

\- exception handling;

\- side effects.



\## Comparison Model



For each relevant behavior classify it as:



\- MATCH

\- DIFFERENCE

\- UNKNOWN



For differences classify further as:



\- DEFECT

\- INTENTIONAL MODERNIZATION

\- ACCEPTABLE IMPLEMENTATION DIFFERENCE

\- REQUIRES BUSINESS CLARIFICATION



\## Compare



Evaluate:



\### Inputs



\- required values;

\- optional values;

\- defaults;

\- null handling;

\- malformed values.



\### Control Flow



\- branching;

\- early exits;

\- retries;

\- loops;

\- ordering.



\### Business Rules



\- calculations;

\- validation;

\- status changes;

\- eligibility;

\- conditional operations.



\### Persistence



\- reads;

\- inserts;

\- updates;

\- deletes;

\- affected tables;

\- ordering;

\- transaction boundaries.



\### Failure Behavior



\- exceptions;

\- returned errors;

\- partial processing;

\- rollback;

\- logging.



\### Operational Behavior



\- duplicate processing;

\- idempotency;

\- concurrency;

\- retries.



\## Implementation Differences



The modern implementation does not need to reproduce legacy code structure.



It must reproduce required observable behavior.



A different implementation is acceptable when:



\- business outcomes match;

\- persistence effects match where required;

\- error semantics remain compatible;

\- no undocumented behavior is lost.



\## Bugs in Legacy Code



Do not automatically reproduce an apparent legacy defect.



Document:



\- legacy behavior;

\- suspected defect;

\- modern behavior;

\- business impact.



Require explicit confirmation when fixing the defect would change observable behavior.



\## Unknown Behavior



Never invent a rule to complete parity.



Mark unresolved behavior as UNKNOWN and identify what evidence is needed.



\## Parity Report



Use:



\### Legacy Behavior

...



\### Modern Behavior

...



\### Classification

MATCH | DIFFERENCE | UNKNOWN



\### Impact

...



\### Evidence

...



\### Recommended Action

...

