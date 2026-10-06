#
# AI Engineering Framework - harness-neutral metadata.
#
# This file describes the canonical framework: its agents, the commands
# generated from workflows and specialist prompts, and which standards are
# delivered where. It contains no harness-specific syntax. Each adapter
# under adapters/ translates it into its harness's native format.
#
# Tool capabilities (translated by each adapter):
#
#   read    - read file contents
#   search  - search files, text, usages, and workspace changes
#   edit    - create and modify files
#   execute - run terminal commands (builds, tests, git)
#   agent   - invoke the agents listed in Agents as subagents
#   web     - fetch URLs / web search
#   todo    - manage a task list
#   ask     - ask the user structured questions
#
# Read-only roles (planner, reviewer, legacy-parity) deliberately receive no
# edit or execute capability, so "do not modify code" is enforced by the
# harness rather than by instructions alone.
#
# Standards lists the role-specific canonical standards delivered with the
# agent. SharedAgentStandards are delivered to every agent by harnesses
# whose subagents may not receive the repository-wide instructions.
#

@{
    # Standards assembled into the repository-wide instructions, in order.
    InstructionStandards = @(
        'development.md'
        'security.md'
        'project-knowledge.md'
        'human-control.md'
    )

    SharedAgentStandards = @(
        'project-knowledge.md'
    )

    # Order matters: it is the generation order and the order of the
    # orchestrator's subagent list.
    Agents = @(
        @{
            Name         = 'orchestrator'
            Description  = 'Coordinates non-trivial engineering work across planning, implementation, testing, review, and legacy parity analysis.'
            ArgumentHint = 'Describe the task, defect, or requirement'
            Tools        = @('read', 'search', 'edit', 'execute', 'agent', 'todo', 'ask')
            Agents       = @('planner', 'developer', 'tester', 'reviewer', 'legacy-parity')
        }

        @{
            Name         = 'planner'
            Description  = 'Investigates software changes and produces implementation plans without modifying production code.'
            ArgumentHint = 'Describe the change or problem to plan'
            Tools        = @('read', 'search', 'web')
        }

        @{
            Name         = 'developer'
            Description  = 'Implements approved software changes using minimal, correct, maintainable modifications.'
            ArgumentHint = 'Describe the approved change or point to the plan'
            Tools        = @('read', 'search', 'edit', 'execute', 'todo')
        }

        @{
            Name         = 'tester'
            Description  = 'Performs adversarial test analysis and creates tests designed to expose defects and regressions.'
            ArgumentHint = 'Name the change or behavior to test'
            Tools        = @('read', 'search', 'edit', 'execute', 'todo')
            Standards    = @('testing.md')
        }

        @{
            Name         = 'reviewer'
            Description  = 'Independently reviews software changes for correctness, risk, architecture, security, and test quality.'
            ArgumentHint = 'Describe the change to review, or the requirement it should satisfy'
            Tools        = @('read', 'search')
            Standards    = @('review.md')
        }

        @{
            Name         = 'legacy-parity'
            Description  = 'Compares modern implementations against authoritative legacy behavior and identifies parity differences.'
            ArgumentHint = 'Name the behavior to compare against the legacy implementation'
            Tools        = @('read', 'search')
            Standards    = @('legacy-parity.md')
        }
    )

    # Commands generated from workflows/ and prompts/.
    #
    #   Name                      - canonical command name
    #   CopilotName               - optional Copilot prompt file name override
    #   Source                    - canonical source, relative to the framework root
    #   Agent                     - agent that executes the command
    #   IncludeWorkingTreeChanges - the harness should provide the current
    #                               uncommitted changes when it can
    Commands = @(
        @{
            Name         = 'feature'
            Source       = 'workflows/feature.md'
            Agent        = 'orchestrator'
            Description  = 'Implement a non-trivial feature using the framework feature-development workflow.'
            ArgumentHint = 'Describe the feature or requirement to implement'
        }

        @{
            Name         = 'bug-fix'
            Source       = 'workflows/bug-fix.md'
            Agent        = 'orchestrator'
            Description  = 'Investigate and fix a defect using root-cause analysis, regression testing, implementation, and review.'
            ArgumentHint = 'Describe the defect: observed vs expected behavior, errors, reproduction steps'
        }

        @{
            Name         = 'migration'
            Source       = 'workflows/migration.md'
            Agent        = 'orchestrator'
            Description  = 'Modernize legacy behavior while explicitly verifying behavioral parity.'
            ArgumentHint = 'Name the legacy behavior to modernize and where the legacy source is'
        }

        @{
            Name                      = 'code-review'
            CopilotName               = 'review'
            Source                    = 'workflows/code-review.md'
            Agent                     = 'reviewer'
            Description               = 'Perform an independent engineering review of the current change.'
            ArgumentHint              = 'Optional: the requirement or plan the change should satisfy'
            IncludeWorkingTreeChanges = $true
        }

        @{
            Name         = 'investigate'
            Source       = 'prompts/investigate.md'
            Agent        = 'planner'
            Description  = 'Investigate a software problem without modifying production code.'
            ArgumentHint = 'Describe the problem or question to investigate'
        }

        @{
            Name         = 'test'
            Source       = 'prompts/test.md'
            Agent        = 'tester'
            Description  = 'Perform adversarial testing of the current implementation.'
            ArgumentHint = 'Name the change, component, or behavior to test'
        }

        @{
            Name         = 'parity'
            Source       = 'prompts/parity.md'
            Agent        = 'legacy-parity'
            Description  = 'Compare modern behavior against an authoritative legacy implementation.'
            ArgumentHint = 'Name the behavior to compare and the legacy and modern locations'
        }

        @{
            Name         = 'bootstrap-knowledge'
            Source       = 'prompts/bootstrap-knowledge.md'
            Agent        = 'orchestrator'
            Description  = 'Bootstrap persistent project knowledge from repository evidence.'
            ArgumentHint = 'Optional: areas of the repository to focus on'
        }
    )
}
