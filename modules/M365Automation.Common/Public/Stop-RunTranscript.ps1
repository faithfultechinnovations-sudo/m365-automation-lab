function Stop-RunTranscript {
  [CmdletBinding()]
  param()
  try { Stop-Transcript | Out-Null } catch {}
}
