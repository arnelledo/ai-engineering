#
# AI Engineering Framework - shared installer helpers.
#
# Dot-sourced by scripts/install.ps1. Functions read the installer's
# script-scope state ($TargetRepo, $Force, $DryRun, $Framework, ...).
#

# ===========================================================================
# Console helpers
# ===========================================================================

function Write-Step {
    param([string]$Message)

    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)

    Write-Host "    $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)

    Write-Host "    $Message" -ForegroundColor Gray
}

function Write-WarningMessage {
    param([string]$Message)

    Write-Host "    WARNING: $Message" -ForegroundColor Yellow
}

# ===========================================================================
# Validation
# ===========================================================================

function Assert-DirectoryExists {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Description does not exist: $Path"
    }
}

function Assert-FileExists {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description does not exist: $Path"
    }
}

function Test-GitAvailable {
    return [bool](Get-Command git -ErrorAction SilentlyContinue)
}

function Invoke-GitQuery {
    # Runs a read-only git command and returns trimmed stdout, or $null on
    # failure. ErrorActionPreference is relaxed locally because Windows
    # PowerShell 5.1 turns native stderr output into terminating errors
    # when ErrorActionPreference is Stop.

    param(
        [string]$RepositoryPath,
        [string[]]$Arguments
    )

    if (-not (Test-GitAvailable)) {
        return $null
    }

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $output = & git -C $RepositoryPath @Arguments 2>$null

        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        return (($output | Out-String).Trim())
    }
    catch {
        return $null
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Test-SamePath {
    param(
        [string]$First,
        [string]$Second
    )

    $a = [System.IO.Path]::GetFullPath($First).TrimEnd('\', '/')
    $b = [System.IO.Path]::GetFullPath($Second).TrimEnd('\', '/')

    return [string]::Equals(
        $a,
        $b,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Assert-RepositoryRoot {
    # Copilot reads .github/ only from the repository root. Installing into
    # a subdirectory would produce files that Copilot silently ignores.

    param([string]$Path)

    # The prefix (the target's path relative to the repository root) is
    # empty at the root. Comparing it avoids comparing absolute paths, which
    # differ when the target path contains a symlink: on macOS, /var and
    # /tmp resolve to /private/var and /private/tmp in git's output.

    $prefix = Invoke-GitQuery `
        -RepositoryPath $Path `
        -Arguments @("rev-parse", "--show-prefix")

    if ($null -ne $prefix) {

        if ($prefix -ne "") {
            $topLevel = Invoke-GitQuery `
                -RepositoryPath $Path `
                -Arguments @("rev-parse", "--show-toplevel")
            $suggested = [System.IO.Path]::GetFullPath($topLevel)

            throw "Target must be the root of a Git repository. Copilot only reads .github/ from the repository root. Repository root: $suggested"
        }

        return
    }

    # git is unavailable or the query failed: require .git directly in the
    # target (a directory, or a file for worktrees and submodules).

    if (-not (Test-Path -LiteralPath (Join-Path $Path ".git"))) {
        throw "Target must be the root of a Git repository (no .git found directly in $Path)."
    }
}

function Get-FrameworkVersion {

    $commit = Invoke-GitQuery `
        -RepositoryPath $FrameworkRoot `
        -Arguments @("rev-parse", "HEAD")

    if (-not $commit) {
        return [ordered]@{
            commit = "unknown"
            uncommittedChanges = $null
        }
    }

    $status = Invoke-GitQuery `
        -RepositoryPath $FrameworkRoot `
        -Arguments @("status", "--porcelain")

    return [ordered]@{
        commit = $commit
        uncommittedChanges = -not [string]::IsNullOrWhiteSpace($status)
    }
}

# ===========================================================================
# File helpers
# ===========================================================================

# Directories already reported by a dry run, so each is reported once.
$DryRunDirectories = @{}

function Ensure-Directory {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path -PathType Container) {
        return
    }

    if ($DryRun) {
        $key = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/').ToLowerInvariant()

        if (-not $DryRunDirectories.ContainsKey($key)) {
            $DryRunDirectories[$key] = $true
            Write-Info "[DryRun] Create directory: $Path"
        }

        return
    }

    New-Item `
        -ItemType Directory `
        -Path $Path `
        -Force | Out-Null
}

function Read-TextFile {
    param([string]$Path)

    Assert-FileExists `
        -Path $Path `
        -Description "Required source file"

    return Get-Content `
        -LiteralPath $Path `
        -Raw `
        -Encoding UTF8
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function ConvertTo-NormalizedText {
    # LF line endings, no BOM character, single trailing newline.

    param([string]$Content)

    $text = $Content.TrimStart([char]0xFEFF)
    $text = $text -replace "`r`n", "`n"
    $text = $text -replace "`r", "`n"

    return $text.TrimEnd("`n") + "`n"
}

function Get-TextHash {
    param([string]$Content)

    $normalized = ConvertTo-NormalizedText $Content
    $bytes = $Utf8NoBom.GetBytes($normalized)
    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    return (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Get-FileTextHash {
    # Hash of a file's normalized text, so that Git line-ending conversion
    # or a BOM does not register as a local modification.

    param([string]$Path)

    $content = [System.IO.File]::ReadAllText($Path, $Utf8NoBom)

    return Get-TextHash $content
}

function Get-RepositoryRelativePath {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    $prefix = $TargetRepo + [System.IO.Path]::DirectorySeparatorChar

    if (-not $full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the target repository: $Path"
    }

    return $full.Substring($prefix.Length).Replace('\', '/')
}

function Write-TextFileNoBom {
    param(
        [string]$Path,
        [string]$Content
    )

    [System.IO.File]::WriteAllText(
        $Path,
        (ConvertTo-NormalizedText $Content),
        $Utf8NoBom
    )
}

# Generated files produced by this run: relative path -> content hash.
$GeneratedFiles = [ordered]@{}

# Generated files skipped by this run because they exist and -Force was not
# supplied.
$SkippedGeneratedFiles = @{}

# Generated files recorded by the previous installation manifest.
$PreviousGeneratedFiles = @{}

# Harness recorded by the previous installation manifest, if any.
$PreviousHarnessId = $null

function Write-GeneratedFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $relativePath = Get-RepositoryRelativePath $Path
    $hash = Get-TextHash $Content

    $parent = Split-Path -Parent $Path

    Ensure-Directory -Path $parent

    $exists = Test-Path -LiteralPath $Path

    if ($exists -and -not $Force) {

        Write-WarningMessage "Skipped existing generated file: $Path"

        # The file is still produced by the framework, so it is not stale.
        # Keep the previous manifest record, if any; a file the framework
        # never wrote is not recorded as generated.
        $SkippedGeneratedFiles[$relativePath] = $true

        if ($PreviousGeneratedFiles.ContainsKey($relativePath)) {
            $GeneratedFiles[$relativePath] = $PreviousGeneratedFiles[$relativePath]
        }

        return $false
    }

    $GeneratedFiles[$relativePath] = $hash

    if ($exists) {

        $currentHash = Get-FileTextHash $Path

        if ($currentHash -eq $hash) {
            Write-Info "Unchanged: $Path"
            return $true
        }

        if (-not $PreviousGeneratedFiles.ContainsKey($relativePath)) {
            Write-WarningMessage "Existing file was not created by the framework and will be overwritten: $Path"
        }
        elseif (
            $PreviousGeneratedFiles[$relativePath] -and
            $PreviousGeneratedFiles[$relativePath] -ne $currentHash
        ) {
            Write-WarningMessage "Local changes will be overwritten (file was modified after the last installation): $Path"
        }
    }

    if ($DryRun) {
        Write-Info "[DryRun] Generate: $Path"
        return $true
    }

    Write-TextFileNoBom -Path $Path -Content $Content

    Write-Success "Generated: $Path"

    return $true
}

function Write-ScaffoldFile {
    param(
        [string]$Path,
        [string]$Content
    )

    # Project-owned files belong to the application repository.
    # Never overwrite them, even when -Force is supplied.

    if (Test-Path -LiteralPath $Path) {
        Write-Info "Preserved project-owned file: $Path"
        return
    }

    $parent = Split-Path -Parent $Path

    Ensure-Directory -Path $parent

    if ($DryRun) {
        Write-Info "[DryRun] Create project scaffold: $Path"
        return
    }

    Write-TextFileNoBom -Path $Path -Content $Content

    Write-Success "Created project scaffold: $Path"
}

function Read-PreviousManifest {

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        return
    }

    try {
        $json = [System.IO.File]::ReadAllText($ManifestPath, $Utf8NoBom).TrimStart([char]0xFEFF)
        $manifest = $json | ConvertFrom-Json
    }
    catch {
        Write-WarningMessage "Could not read previous manifest; stale-file cleanup is skipped: $ManifestPath"
        return
    }

    $properties = $manifest.PSObject.Properties.Name

    # Manifests written before multi-harness support are GitHub Copilot.
    $script:PreviousHarnessId = "github-copilot"

    if (($properties -contains "harness") -and $manifest.harness) {
        $script:PreviousHarnessId = [string]$manifest.harness
    }

    if (-not ($properties -contains "generated")) {
        return
    }

    foreach ($entry in @($manifest.generated)) {

        if ($entry -is [string]) {
            # Manifest written by an earlier installer version: no hashes.
            $PreviousGeneratedFiles[$entry] = $null
        }
        elseif ($entry.PSObject.Properties.Name -contains "path") {
            $PreviousGeneratedFiles[$entry.path] = $entry.sha256
        }
    }
}

function Remove-EmptyParentDirectories {
    # After removing a generated file, removes directories it leaves empty,
    # walking up towards (but never removing) the repository root.

    param([string]$Path)

    $directory = Split-Path -Parent $Path

    while (
        $directory -and
        -not (Test-SamePath $directory $TargetRepo) -and
        (Test-Path -LiteralPath $directory -PathType Container) -and
        -not (Get-ChildItem -LiteralPath $directory -Force | Select-Object -First 1)
    ) {
        Remove-Item -LiteralPath $directory -Force
        Write-Info "Removed empty directory: $(Get-RepositoryRelativePath $directory)"
        $directory = Split-Path -Parent $directory
    }
}

function Remove-StaleGeneratedFiles {
    # Removes files generated by a previous installation that the current
    # run no longer produces: framework files that were renamed or removed,
    # or the previous harness's files when switching harness. Only
    # unmodified files under the previous harness's managed paths are
    # removed, and only when -Force is supplied.

    param([string[]]$ManagedPrefixes)

    Write-Step "Checking for stale generated files"

    $stale = @(
        $PreviousGeneratedFiles.Keys |
            Where-Object { -not $GeneratedFiles.Contains($_) -and -not $SkippedGeneratedFiles.ContainsKey($_) } |
            Sort-Object
    )

    if ($stale.Count -eq 0) {
        Write-Info "No stale generated files."
        return
    }

    foreach ($relativePath in $stale) {

        $isManaged = $false

        foreach ($prefix in $ManagedPrefixes) {
            if ($relativePath.StartsWith($prefix)) {
                $isManaged = $true
            }
        }

        if (-not $isManaged) {
            Write-WarningMessage "Not removing stale entry outside the harness's managed paths: $relativePath"
            continue
        }

        $fullPath = Join-Path $TargetRepo ($relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))

        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            continue
        }

        $recordedHash = $PreviousGeneratedFiles[$relativePath]

        if (-not $recordedHash) {
            Write-WarningMessage "Stale generated file kept (no recorded hash to confirm it is unmodified). Remove manually if no longer needed: $relativePath"
            continue
        }

        if ((Get-FileTextHash $fullPath) -ne $recordedHash) {
            Write-WarningMessage "Stale generated file kept (modified after installation). Remove manually if no longer needed: $relativePath"
            continue
        }

        if (-not $Force) {
            Write-WarningMessage "Stale generated file (no longer produced by the framework). Run with -Force to remove: $relativePath"
            continue
        }

        if ($DryRun) {
            Write-Info "[DryRun] Remove stale generated file: $relativePath"
            continue
        }

        Remove-Item -LiteralPath $fullPath -Force

        Write-Success "Removed stale generated file: $relativePath"

        Remove-EmptyParentDirectories -Path $fullPath
    }
}

# ===========================================================================

# ===========================================================================
# Framework model
# ===========================================================================

function Get-FrameworkAgent {
    param([string]$Name)

    $agent = $Framework.Agents | Where-Object { $_.Name -eq $Name } | Select-Object -First 1

    if (-not $agent) {
        throw "Unknown framework agent '$Name'."
    }

    return $agent
}

function Get-AgentStandards {
    # Role-specific standards first (they are what the agent body refers
    # to most), then, when requested, the shared standards.

    param(
        [string]$AgentName,
        [switch]$IncludeShared
    )

    $agent = Get-FrameworkAgent $AgentName
    $standards = @()

    if ($agent.ContainsKey("Standards")) {
        $standards += $agent.Standards
    }

    if ($IncludeShared) {
        $standards += $Framework.SharedAgentStandards
    }

    return $standards
}

function Get-CommandBody {
    param([hashtable]$Command)

    return Read-TextFile (Join-Path $FrameworkRoot $Command.Source)
}

function Assert-FrameworkModel {
    # Validates framework.psd1 and the canonical sources it references.

    $agentNames = @($Framework.Agents | ForEach-Object { $_.Name })

    $duplicates = @($agentNames | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($duplicates.Count -gt 0) {
        throw "Duplicate agent names in framework.psd1: $($duplicates -join ', ')"
    }

    $knownCapabilities = @("read", "search", "edit", "execute", "agent", "web", "todo", "ask")

    $requiredFiles = @()

    foreach ($agent in $Framework.Agents) {

        if (-not $agent.Tools -or @($agent.Tools).Count -eq 0) {
            throw "Agent '$($agent.Name)' must declare an explicit tool list."
        }

        foreach ($tool in $agent.Tools) {
            if ($knownCapabilities -notcontains $tool) {
                throw "Agent '$($agent.Name)' declares unknown tool capability '$tool'."
            }
        }

        if ($agent.ContainsKey("Agents")) {

            if ($agent.Tools -notcontains "agent") {
                throw "Agent '$($agent.Name)' declares subagents but does not include the 'agent' tool."
            }

            foreach ($subagent in $agent.Agents) {
                if ($agentNames -notcontains $subagent) {
                    throw "Agent '$($agent.Name)' references unknown subagent '$subagent'."
                }
            }
        }

        $requiredFiles += (Join-Path $AgentsRoot "$($agent.Name).md")

        foreach ($standard in (Get-AgentStandards $agent.Name -IncludeShared)) {
            $requiredFiles += (Join-Path $StandardsRoot $standard)
        }
    }

    $commandNames = @($Framework.Commands | ForEach-Object { $_.Name })

    $duplicates = @($commandNames | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($duplicates.Count -gt 0) {
        throw "Duplicate command names in framework.psd1: $($duplicates -join ', ')"
    }

    foreach ($command in $Framework.Commands) {

        if ($agentNames -notcontains $command.Agent) {
            throw "Command '$($command.Name)' targets unknown agent '$($command.Agent)'."
        }

        $requiredFiles += (Join-Path $FrameworkRoot $command.Source)
    }

    foreach ($standard in $Framework.InstructionStandards) {
        $requiredFiles += (Join-Path $StandardsRoot $standard)
    }

    foreach ($file in $requiredFiles) {
        Assert-FileExists -Path $file -Description "Required framework file"
    }

    # Every canonical standard must be delivered somewhere. A standard that
    # no agent and no instruction file uses would silently never reach the
    # target repository.

    $deliveredStandards = @($Framework.InstructionStandards)

    foreach ($agent in $Framework.Agents) {
        $deliveredStandards += Get-AgentStandards $agent.Name -IncludeShared
    }

    $undeliveredStandards = @(
        Get-ChildItem -LiteralPath $StandardsRoot -Filter "*.md" -File |
            Where-Object { $deliveredStandards -notcontains $_.Name } |
            ForEach-Object { $_.Name }
    )

    if ($undeliveredStandards.Count -gt 0) {
        throw "These standards are not delivered to any agent or instruction file: $($undeliveredStandards -join ', '). Add them to InstructionStandards or an agent's Standards list in scripts/framework.psd1."
    }
}

# ===========================================================================
# YAML frontmatter helpers
# ===========================================================================

function ConvertTo-YamlDoubleQuoted {
    # YAML double-quoted scalar with backslash and double-quote escaped.

    param([string]$Value)

    if ($Value -match "[`r`n]") {
        throw "Frontmatter values must be single-line: $Value"
    }

    return '"' + ($Value.Replace('\', '\\').Replace('"', '\"')) + '"'
}

function ConvertTo-YamlInlineList {
    param([string[]]$Items)

    if (-not $Items -or $Items.Count -eq 0) {
        return "[]"
    }

    $quoted = $Items | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }

    return "[" + ($quoted -join ", ") + "]"
}

# ===========================================================================
# JSON
# ===========================================================================

function ConvertTo-JsonString {
    param([string]$Value)

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')

    foreach ($char in $Value.ToCharArray()) {
        switch ($char) {
            '"' { [void]$builder.Append('\"') }
            '\' { [void]$builder.Append('\\') }
            "`n" { [void]$builder.Append('\n') }
            "`r" { [void]$builder.Append('\r') }
            "`t" { [void]$builder.Append('\t') }
            default {
                if ([int]$char -lt 0x20) {
                    [void]$builder.Append(('\u{0:x4}' -f [int]$char))
                }
                else {
                    [void]$builder.Append($char)
                }
            }
        }
    }

    [void]$builder.Append('"')

    return $builder.ToString()
}

function ConvertTo-StableJson {
    # JSON with two-space indentation that is identical on Windows
    # PowerShell 5.1 and PowerShell 7, whose ConvertTo-Json output differs.
    # Supports dictionaries, arrays, strings, booleans, numbers, and null.

    param(
        [AllowNull()]
        [object]$Value,
        [int]$Depth = 0
    )

    $indent = "  " * ($Depth + 1)
    $closingIndent = "  " * $Depth

    if ($null -eq $Value) {
        return "null"
    }

    if ($Value -is [bool]) {
        return $(if ($Value) { "true" } else { "false" })
    }

    if ($Value -is [string]) {
        return ConvertTo-JsonString $Value
    }

    if ($Value -is [int] -or $Value -is [long]) {
        return $Value.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    }

    if ($Value -is [System.Collections.IDictionary]) {
        if ($Value.Count -eq 0) {
            return "{}"
        }

        $members = foreach ($key in $Value.Keys) {
            $indent + (ConvertTo-JsonString ([string]$key)) + ": " +
                (ConvertTo-StableJson -Value $Value[$key] -Depth ($Depth + 1))
        }

        return "{`n" + ($members -join ",`n") + "`n$closingIndent}"
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $items = foreach ($item in $Value) {
            $indent + (ConvertTo-StableJson -Value $item -Depth ($Depth + 1))
        }

        if (-not $items) {
            return "[]"
        }

        return "[`n" + (@($items) -join ",`n") + "`n$closingIndent]"
    }

    throw "Unsupported JSON value type: $($Value.GetType().FullName)"
}

# ===========================================================================
# Markdown composition
# ===========================================================================

function Step-MarkdownHeadingLevel {
    # Demotes every Markdown heading by one level (# -> ##), outside fenced
    # code blocks. Used when a standard is embedded under another document's
    # top-level heading, so each generated file has a single H1.

    param([string]$Markdown)

    $inFence = $false
    $lines = ($Markdown -replace "`r`n", "`n") -split "`n"

    $result = foreach ($line in $lines) {

        if ($line -match '^\s*(```|~~~)') {
            $inFence = -not $inFence
            $line
            continue
        }

        if (-not $inFence -and $line -match '^#{1,5} ') {
            "#" + $line
        }
        else {
            $line
        }
    }

    return ($result -join "`n")
}

function Get-EmbeddedStandard {
    param([string]$StandardFile)

    $text = (Read-TextFile (Join-Path $StandardsRoot $StandardFile)).Trim()

    return Step-MarkdownHeadingLevel $text
}

# ===========================================================================

# ===========================================================================
# Manifest
# ===========================================================================

function Install-Manifest {

    param(
        [string]$HarnessId,
        [string[]]$ProjectOwned
    )

    Write-Step "Writing framework manifest"

    # No timestamp: the manifest only changes when the framework commit or
    # the generated content changes, which keeps Git diffs meaningful.

    $generated = @(
        $GeneratedFiles.Keys | Sort-Object | ForEach-Object {
            [ordered]@{
                path = $_
                sha256 = $GeneratedFiles[$_]
            }
        }
    )

    $manifest = [ordered]@{
        framework = "ai-engineering-framework"
        manifestVersion = 2
        harness = $HarnessId
        frameworkVersion = Get-FrameworkVersion
        generated = $generated
        projectOwned = @($ProjectOwned)
    }

    if ($manifest.frameworkVersion.uncommittedChanges) {
        Write-WarningMessage "The framework repository has uncommitted changes. The recorded commit does not fully describe the installed content."
    }

    $json = ConvertTo-StableJson $manifest

    # The manifest is not recorded in its own generated-file list.

    if ((Test-Path -LiteralPath $ManifestPath) -and -not $Force) {
        Write-WarningMessage "Skipped existing manifest: $ManifestPath"
        return
    }

    if (
        (Test-Path -LiteralPath $ManifestPath) -and
        ((Get-FileTextHash $ManifestPath) -eq (Get-TextHash $json))
    ) {
        Write-Info "Unchanged: $ManifestPath"
        return
    }

    if ($DryRun) {
        Write-Info "[DryRun] Write manifest: $ManifestPath"
        return
    }

    Write-TextFileNoBom -Path $ManifestPath -Content $json

    Write-Success "Written: $ManifestPath"
}

# ===========================================================================
