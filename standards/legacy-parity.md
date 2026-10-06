# Legacy Parity Standards

## Purpose

Modernization does not automatically mean changing behavior.

When replacing a legacy implementation, preserve observable business behavior unless a behavior change is explicitly required.

## Source of Truth

Determine which legacy implementation is authoritative.

Do not infer legacy behavior only from documentation if executable legacy code is available.

Inspect actual:

- control flow;
- conditions;
- database operations;
- calculations;
- defaults;
- exception handling;
- side effects.

## Comparison Model

Classify every significant behavior as exactly one of:

### MATCH

Observable behavior is equivalent.

### DIFFERENCE

Observable behavior differs.

### UNKNOWN

Available evidence is insufficient to establish parity.

Do not convert UNKNOWN into MATCH based on assumptions.

### Difference Types

Classify each DIFFERENCE further as exactly one of:

- PROBABLE DEFECT;
- INTENTIONAL MODERNIZATION;
- ACCEPTABLE IMPLEMENTATION DIFFERENCE;
- REQUIRES BUSINESS CLARIFICATION.

## Compare

Evaluate:

### Inputs

- required values;
- optional values;
- validation;
- defaults;
- null handling;
- malformed values.

### Control Flow

- branching;
- early exits;
- retries;
- loops;
- ordering.

### Business Rules

- calculations;
- validation;
- status changes and state transitions;
- eligibility;
- conditional operations.

### Persistence

- reads;
- inserts;
- updates;
- deletes;
- records that are not created;
- default values;
- affected tables;
- ordering;
- transaction boundaries;
- rollback.

### Failure Behavior

- exceptions;
- returned errors;
- partial processing;
- rollback;
- logging.

### Operational Behavior

- duplicate processing;
- repeated execution;
- idempotency;
- concurrency;
- retries.

### Integrations

- external system calls;
- messages published or consumed;
- other observable side effects.

## Implementation Differences

The modern implementation does not need to reproduce legacy code structure.

It must reproduce required observable behavior.

Examples of acceptable structural differences include:

- different class structure;
- dependency injection;
- asynchronous execution;
- ORM use instead of direct SQL;
- different internal abstractions.

A different implementation is acceptable only when:

- business outcomes match;
- persistence effects match where required;
- error semantics remain compatible;
- no undocumented behavior is lost.

## Bugs in Legacy Code

Do not automatically reproduce an apparent legacy defect.

Do not silently fix an apparent legacy defect when doing so changes observable behavior.

Document:

- legacy behavior;
- suspected defect;
- modern behavior;
- business impact.

Classify the difference and require explicit approval when fixing the defect would change established business behavior.

## Unknown Behavior

Never invent a rule to complete parity.

Mark unresolved behavior as UNKNOWN and identify what evidence is needed.

## Parity Report

For each significant behavior report:

### Behavior

Describe the observable behavior.

### Legacy

Describe legacy behavior and evidence.

### Modern

Describe modern behavior and evidence.

### Classification

MATCH, DIFFERENCE, or UNKNOWN.

### Difference Type

For a DIFFERENCE: PROBABLE DEFECT, INTENTIONAL MODERNIZATION, ACCEPTABLE IMPLEMENTATION DIFFERENCE, or REQUIRES BUSINESS CLARIFICATION.

### Impact

Describe practical business or technical impact.

### Evidence

Identify relevant source, tests, database behavior, or other evidence.

### Recommended Action

Describe the required next step.
