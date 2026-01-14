param (
    [Parameter(Mandatory)]
    [string]$UserPrincipalName,

    [string[]]$GroupObjectIds,
    [switch]$DryRun
)

Write-Host "Starting user restore for $UserPrincipalName"

if ($DryRun) {
    Write-Host "[DryRun] Would restore user and groups"
    return
}

Update-MgUser -UserId $UserPrincipalName -AccountEnabled:$true

foreach ($groupId in $GroupObjectIds) {
    New-MgGroupMember -GroupId $groupId -DirectoryObjectId $UserPrincipalName
}

Write-Host "Restore completed"

