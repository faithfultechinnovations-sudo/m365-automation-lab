Install-Module Microsoft.Graph -Scope CurrentUser

 -UserPrincipalName "jane.doe@contoso.com" `
  -DryRun
  -UserPrincipalName "jane.doe@contoso.com"

  -UserPrincipalName "jane.doe@contoso.com" `
  -GroupObjectIds @(
    "11111111-1111-1111-1111-111111111111",
    "22222222-2222-2222-2222-222222222222"
  )
