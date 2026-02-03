function Write-RunSummary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Area,
    [Parameter(Mandatory)][string]$RunName,
    [Parameter(Mandatory)][hashtable]$Summary
  )

  $root = Get-RepoRoot
  $safe = Sanitize-FileName $RunName
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"

  $dir = Join-Path $root "logs/$Area"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  $path = Join-Path $dir "$Area-$safe-$ts.summary.json"
  ($Summary | ConvertTo-Json -Depth 10) | Out-File -Encoding UTF8 $path
  return $path
}
