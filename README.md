# AI Engineering Framework

Reusable, harness-independent standards, agents, and workflows for AI-assisted software engineering.

## Goals

- Improve correctness of AI-generated changes.
- Reduce unnecessary code modifications.
- Require investigation before implementation.
- Improve automated testing quality.
- Introduce independent code review.
- Support legacy modernization and behavioral parity.
- Remain portable across AI development tools.

## Structure

`standards/`

Defines engineering rules.

`agents/`

Defines specialized engineering roles.

`workflows/`

Defines repeatable development processes.

`adapters/`

Contains tool-specific integrations for Copilot, Claude, Cursor, and other AI harnesses.

## Design Principle

The framework is vendor-independent.

Tool-specific adapters should reference these standards rather than duplicating them.

Project-specific architecture and business knowledge do not belong in this repository.

They belong in each application's own AI/project documentation.

## Precedence

When instructions conflict, use this order:

1. Explicit human instruction for the current task
2. Project-specific mandatory requirements
3. Project architecture and business rules
4. This framework
5. Tool defaults

Security and data-integrity constraints must not be overridden implicitly.

## Core Workflow

For non-trivial work:

Understand

→ Investigate

→ Plan

→ Implement

→ Test

→ Review

→ Correct

→ Verify

→ Human approval
