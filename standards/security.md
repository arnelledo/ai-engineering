\# Security Standards



\## Purpose



Security must be considered during implementation and review without unnecessarily expanding task scope.



\## Secrets



Never:



\- hard-code passwords;

\- hard-code API keys;

\- commit tokens;

\- expose connection credentials;

\- log authentication secrets.



Use the project's approved configuration and secret-management mechanisms.



\## Sensitive Data



Avoid logging:



\- credentials;

\- access tokens;

\- session identifiers;

\- private keys;

\- payment information;

\- sensitive personal information.



\## Input



Treat external input as untrusted.



Evaluate:



\- validation;

\- encoding;

\- injection;

\- path traversal;

\- unsafe deserialization;

\- command execution;

\- file upload risks.



\## Authentication and Authorization



Authentication answers who the caller is.



Authorization answers what the caller may do.



Do not rely on UI restrictions as authorization.



Enforce authorization at appropriate backend boundaries.



\## Database



Use parameterized queries or approved ORM patterns.



Do not construct SQL using untrusted string concatenation.



\## External Calls



Validate assumptions about external responses.



Consider:



\- timeout;

\- failure;

\- retry;

\- authentication;

\- certificate validation;

\- unexpected payloads.



\## Dependencies



Do not introduce dependencies with unnecessary privileges or capabilities.



Do not upgrade security-sensitive packages casually as part of unrelated tasks.



\## Security Findings



Do not label theoretical issues as exploitable vulnerabilities without evidence.



Describe:



\- attack/failure scenario;

\- required preconditions;

\- impact;

\- recommended mitigation.

