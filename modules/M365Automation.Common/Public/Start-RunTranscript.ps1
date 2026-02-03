function Start-RunTranscript {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Area,
    [Parameter(Mandatory)][string]$RunName
  )

  $root = Get-RepoRoot
  $safe = Sanitize-FileName $RunName
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"

  $dir = Join-Path $root "logs/transcripts"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  $path = Join-Path $dir "$Area-$safe-$ts.transcript.txt"
  Start-Transcript -Path $path -Append | Out-Null
  return $path
}
