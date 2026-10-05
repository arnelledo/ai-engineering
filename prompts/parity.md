# Legacy Parity Analysis

Compare the modern implementation against the authoritative legacy implementation.

Before comparison, inspect relevant project knowledge under:

- `.ai/business-rules/`
- `.ai/database/`
- `.ai/integrations/`
- `.ai/legacy/`
- `.ai/decisions/`
- `.ai/tasks/`

Analyze both implementations independently before comparing them.

Compare:

- inputs;
- validation;
- default behavior;
- null handling;
- branching;
- calculations;
- database reads and writes;
- transaction behavior;
- errors;
- retries;
- duplicates;
- ordering;
- external integrations;
- observable side effects.

Classify each behavior as:

- MATCH
- DIFFERENCE
- UNKNOWN

For DIFFERENCE, classify it as:

- probable defect;
- intentional modernization;
- acceptable implementation difference;
- requires business clarification.

Do not require structural similarity when observable behavior is equivalent.

Do not silently correct apparent legacy defects when doing so would change observable behavior.

Report evidence for each significant conclusion and identify durable legacy knowledge that should be documented.