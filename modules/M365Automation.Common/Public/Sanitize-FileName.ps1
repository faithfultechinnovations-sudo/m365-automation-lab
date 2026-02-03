function Sanitize-FileName {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Name)

  $invalid = [IO.Path]::GetInvalidFileNameChars()
  ($Name.ToCharArray() | ForEach-Object { if ($invalid -contains $_) { "_" } else { $_ } }) -join ""
}
