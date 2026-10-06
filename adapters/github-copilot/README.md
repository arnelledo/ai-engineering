# GitHub Copilot Adapter

`adapter.ps1` translates the canonical framework into GitHub Copilot's format. See the [README](../../README.md) for what it generates and how to use it.

## Copilot Coding Agent Setup

The installer does not create `.github/workflows/copilot-setup-steps.yml`. The build and test environment depends on each application's stack, and the file is a CI workflow, so the repository team adds it.

Without it, the Copilot coding agent on GitHub.com may be unable to build or run tests, and the agents will report verification as not performed.

Create `.github/workflows/copilot-setup-steps.yml` with a single job named `copilot-setup-steps`. For example, for a .NET application:

```yaml
name: Copilot Setup Steps

on: workflow_dispatch

jobs:
  copilot-setup-steps:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: "8.0.x"
      - run: dotnet restore
```

See GitHub's documentation on customizing the coding agent environment for the full set of options.

## Version Notes

Older VS Code releases used `.chatmode.md` files and a `mode:` field in prompt files. The adapter does not generate those formats; use a current VS Code and Copilot Chat.
