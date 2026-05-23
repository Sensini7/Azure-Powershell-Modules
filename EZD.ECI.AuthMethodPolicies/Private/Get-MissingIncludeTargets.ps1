function Get-MissingIncludeTargets {
    # Calculate missing include targets
    if(($IncludeTargetsToRemove.Count -gt 0) -and ($IncludeTargets.id -NotContains "all_users") -and ($ParamState -eq "enabled"))
    {
        Write-Host "WARNING: At least one Entra ID group currently configured in the include targets is not present in the list of desired include targets. To avoid unintentional loss of access, no changes to include targets will be made."
        Write-Host "Verify that the list of include targets is accurate. If it is, manually remove the include targets from Entra ID that are no longer needed before re-running this script."
        Write-Host "These are the object IDs of the Entra ID groups currently configured in the include targets which are not present in the desired configuration:"
        $MissingIncludeTargets | foreach { Write-Host $_ }
        return 1
    }
    elseif($ParamState -ne "enabled")
    {
        Write-Host "Desired state of $CurrentMethod authentication method is disabled. Bypassing missing targets check since include targets do not impact disabled methods."
        return 2
    }
    elseif($IncludeTargets.id -Contains "all_users")
    {
        Write-Host "Desired state of $CurrentMethod include targets includes all_users. Bypassing missing targets since all_users is inclusive of all groups."
        return 2
    }
    else
    {
        Write-Host "There are no Entra ID groups configured in include targets which are not present in the desired configuration. This is expected. Proceeding."
        return 2
    }

}