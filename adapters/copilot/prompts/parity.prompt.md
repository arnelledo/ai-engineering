# Legacy Parity Analysis

Compare the modern implementation against the authoritative legacy implementation.

Do not modify code during the initial analysis.

Trace both implementations independently.

Compare:

- inputs;
- validation;
- defaults;
- null behavior;
- branching;
- calculations;
- database reads;
- inserts;
- updates;
- deletes;
- transaction behavior;
- errors;
- retries;
- duplicate behavior;
- ordering;
- external side effects.

Classify each material behavior as:

- MATCH
- DIFFERENCE
- UNKNOWN

For each DIFFERENCE determine whether it is:

- probable defect;
- intentional modernization;
- equivalent implementation difference;
- requires business clarification.

Do not require identical implementation structure.

Compare observable behavior.

Do not assume modern behavior is preferable merely because it is newer.

Report:

### Overall Parity Assessment

### Behavior Comparison

### Blocking Differences

### Non-Blocking Differences

### Unknowns Requiring Clarification

### Required Regression Tests