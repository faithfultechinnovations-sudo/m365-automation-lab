function Get-RepoRoot {
  [CmdletBinding()]
  param()

  try {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $root) { return $root.Trim() }
  } catch {}

  $p = (Get-Location).Path
  while ($p -and -not (Test-Path (Join-Path $p ".git"))) {
    $parent = Split-Path $p -Parent
    if ($parent -eq $p) { break }
    $p = $parent
  }

  if (-not (Test-Path (Join-Path $p ".git"))) { throw "Unable to locate repo root (.git)." }
  return $p
}
