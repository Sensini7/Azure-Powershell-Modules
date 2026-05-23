function Get-StandardAuthMethodChecks {

    # Reset variables if already set
    $IncludeTargetsToAdd = @()
    $IncludeTargetsToRemove = @()
    $DriftCounter = 0

    # Validate whether include targets align with desired settings
    Write-Host "----------------------------------------------------------------------------------------------------"
    Write-Host "Now evaluating drift for $CurrentMethod."
    Write-Host "Now evaluating $CurrentMethod include targets to determine if they align with desired settings."
    foreach($IncludeTarget in $IncludeTargets)
    {
        $IncludeTargetId = $IncludeTarget.Id
        if($CloudIncludeTargets.id -Contains $IncludeTargetId)
        {
            Write-Host "`tGroup with ID $IncludeTargetId is included in the current $CurrentMethod include targets."
        }
        elseif($CloudIncludeTargets.id -NotContains $IncludeTargetId)
        {
            Write-Host "`tGroup with ID $IncludeTargetId is not included in the current $CurrentMethod include targets. It should be added."
            $IncludeTargetsToAdd += $IncludeTargetId
            $DriftCounter += 1
        }
        else
        {
            Write-Host "`tERROR: Failed to evaluate if group with object ID $IncludeTargetId is included in the current $CurrentMethod include targets."
            $IncludeTargetsToAdd += $IncludeTargetId
            $DriftCounter += 1
        }
    }
    if(!$IncludeTargetsToAdd)
    {
        Write-Host "There are no $CurrentMethod include targets in the desired state which are not present in the current state. No change is necessary."
    }
    
    foreach($CloudIncludeTarget in $CloudIncludeTargets)
    {
        $CloudTargetId = $CloudIncludeTarget.id
        if(($IncludeTargets.id -NotContains $CloudTargetId))
        {
            Write-Host "`tGroup with ID $CloudTargetId is in the current $CurrentMethod include targets but not the desired state. It should be removed."
            $IncludeTargetsToRemove += $CloudTargetId
            $DriftCounter += 1
        }
    }
    if(!$IncludeTargetsToRemove)
    {
        Write-Host "There are no $CurrentMethod include targets currently configured in the tenant which are not present in the desired state. No change is necessary."
    }

    # Validate whether authentication method state aligns with desired state
    if($ParamState -eq $CloudAuthenticationMethodConfiguration.State)
    {
        Write-Host "$CurrentMethod authentication method state is configured as desired ($ParamState). No change to state is necessary."
    }
    else {
        Write-Host "$CurrentMethod authentication method state is not configured as desired. Parameter state should be set to $ParamState."
        $DriftCounter += 1
    }

    return @{ "IncludeTargetsToAdd" = $IncludeTargetsToAdd; "IncludeTargetsToRemove" = $IncludeTargetsToRemove; "DriftCounter" = $DriftCounter }

}