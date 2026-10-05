# Investigate

Investigate the requested problem.

Do not modify production code.

Before investigation:

1. inspect `.ai/project.md`;
2. inspect `.ai/architecture.md`;
3. inspect relevant persistent project knowledge;
4. inspect related active task context when available.

Determine:

- relevant execution flow;
- relevant files and components;
- callers and downstream dependencies;
- current behavior;
- expected behavior;
- persistence effects;
- integration effects;
- transaction and concurrency considerations;
- relevant tests;
- likely root cause;
- evidence supporting the conclusion.

If legacy behavior is relevant, identify the authoritative implementation and compare observable behavior.

Clearly separate confirmed evidence from hypotheses.

Report:

1. Requirement / problem
2. Relevant project knowledge
3. Execution flow
4. Relevant files
5. Current behavior
6. Expected behavior
7. Root cause or leading hypotheses
8. Persistence / integration effects
9. Risks
10. Recommended implementation
11. Recommended tests
12. Project knowledge impact
13. Unknowns requiring clarification