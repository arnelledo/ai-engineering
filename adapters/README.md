# Harness Adapters

This directory is reserved for harness-specific adapter logic.

Canonical engineering instructions must not be duplicated here.

The source of truth lives in:

- `standards/`
- `agents/`
- `workflows/`
- `prompts/`

Adapters should contain only harness-specific metadata, templates, transformations, or deployment logic required to convert canonical framework definitions into a format understood by a particular AI harness.

## GitHub Copilot

GitHub Copilot is currently supported directly by `scripts/install.ps1`.

The installer generates Copilot-native files in the target repository from the canonical framework definitions.

## Future Harnesses

Future adapters may be added for harnesses such as:

- Claude
- Cursor

Those adapters should consume the canonical framework rather than maintain independent copies of engineering instructions.