# Security Review Standards

## Purpose

A security review determines whether a change lets a caller do, read, or cause something it should not.

It complements the Code Review Standards. It does not repeat the general review.

## Scope

Review the trust boundaries the change adds or touches, as listed under Security-Sensitive Changes in the Security Standards.

Do not audit the whole application. Report pre-existing weaknesses only when the change makes them reachable or worse.

## Review Method

### Map Trust Boundaries

Identify where the change accepts data or requests from a less trusted source:

- HTTP endpoints, message handlers, and scheduled jobs;
- files, uploads, and imports;
- external service responses;
- configuration and environment values;
- data previously stored from untrusted input.

### Trace Sources to Sinks

For each untrusted source, follow the data to every place it is used.

Sinks include:

- SQL and other query languages;
- shell commands and process arguments;
- file system paths;
- HTML, templates, and log output;
- deserializers;
- redirects and outbound URLs;
- authorization and pricing decisions.

At each sink, establish what validation, encoding, or parameterization applies, and whether it applies on every path.

### Check Authorization

For each operation the change exposes or modifies, determine:

- who may call it;
- which resource the caller may act on, not only which operation;
- where the check is enforced, and whether every path passes through it.

Treat a missing ownership or tenant check as a finding, not a style concern.

### Check Secrets and Sensitive Data

Determine whether the change stores, logs, returns, or transmits credentials, tokens, keys, or sensitive personal data.

### Check Failure Behavior

Determine whether errors, timeouts, and partial failures fail closed, and whether error responses expose internal details.

### Check Dependencies

For added or upgraded dependencies, determine:

- why the dependency is needed;
- what privileges or capabilities it requires;
- whether the version has known security advisories, when that can be established.

## Evidence

Report a vulnerability only when a concrete path exists from a source the attacker controls to the affected sink or operation.

When a path depends on facts not visible in the repository, such as gateway configuration or infrastructure policy, report it as a question, not a finding.

Apply the Security Findings requirements in the Security Standards: scenario, preconditions, impact, and mitigation.

## Output

Report findings, questions, and the verdict using the severity levels, finding format, and verdicts in the Code Review Standards.

Include the trust boundaries reviewed, so missing coverage is visible.
