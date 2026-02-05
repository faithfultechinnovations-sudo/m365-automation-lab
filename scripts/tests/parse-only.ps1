[CmdletBinding()]
param (
    [switch]$StagedOnly,
    [string]$RootPath = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = 'Stop'

function Get-StagedPowerShellFiles {
    git diff --cached --name-only --diff-filter=ACM |
        Where-Object { $_ -match '\.(ps1|psm1|psd1)$' } |
        ForEach-Object { Resolve-Path $_ -ErrorAction SilentlyContinue }
}

Write-Host "🔍 PowerShell parse validation"

if ($StagedOnly) {
    Write-Host "Mode: staged files only"
    $files = Get-StagedPowerShellFiles
} else {
    Write-Host "Mode: full repository scan"
    $files = Get-ChildItem -Path $RootPath -Recurse -File -Include *.ps1,*.psm1,*.psd1 |
        Where-Object { $_.FullName -notmatch '\\\.git\\|\\node_modules\\|\\dist\\' }
}

if (-not $files) {
    Write-Host "No PowerShell files to validate."
    exit 0
}

$failed = $false

foreach ($file in $files) {
    Write-Host "• Parsing $($file.Path)"

    $tokens = $null
    $errors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        $file.Path,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null

    if ($errors.Count -gt 0) {
        $failed = $true
        Write-Error "❌ Parse errors in $($file.Path)"
        $errors | ForEach-Object {
            Write-Error ("  Line {0}:{1} {2}" -f $_.Extent.StartLineNumber, $_.Extent.StartColumnNumber, $_.Message)
        }
    }
}

if ($failed) {
    Write-Error "🚫 PowerShell parse validation FAILED"
    exit 1
}

Write-Host "✅ PowerShell parse validation PASSED"
exit 0
