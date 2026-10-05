# Implement Approved Change

Implement the requested or approved change.

Before modifying code, confirm that the affected execution path and intended behavior are understood.

## Rules

- Follow repository architecture.
- Follow existing patterns.
- Make the smallest correct change.
- Do not perform unrelated refactoring.
- Do not silently change business behavior.
- Preserve backwards compatibility where required.
- Do not weaken validation or error handling.
- Do not modify tests merely to hide implementation defects.
- Do not introduce dependencies without a concrete need.

If repository evidence contradicts the proposed implementation, stop and explain the discrepancy before making broad changes.

## Verification

After implementation:

1. Build affected projects.
2. Run relevant tests.
3. Add or update tests for changed behavior.
4. Inspect the final diff.
5. Check for unrelated modifications.

Report:

### Implementation Summary

### Files Changed

### Behavioral Changes

### Persistence Impact

### Tests

### Verification

### Remaining Risks / Assumptions