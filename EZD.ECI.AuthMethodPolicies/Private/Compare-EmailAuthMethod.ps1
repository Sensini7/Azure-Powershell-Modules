function Compare-EmailAuthMethod {

    # Calculate drift of the current state from the desired state

    <#
        Drift detection checks specific to the authentication method would go here. There are currently no auth method checks specific to this auth method.
    #>

    Write-Host "===================================================================================================="
    
    # Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        if($IncludeTargetsToAdd.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Groups are missing from $CurrentMethod include targets -> DESIRED: These include targets should be added:"
            $IncludeTargetsToAdd | foreach { $DriftSummary += Write-Output `t$_ }
        }
        if($IncludeTargetsToRemove.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Groups are in the $CurrentMethod include targets which are not in the desired state -> DESIRED: These include targets should be removed:"
            $IncludeTargetsToRemove | foreach { $DriftSummary += Write-Output `t$_ }
        }
        if($ParamState -ne $CloudAuthenticationMethodConfiguration.State)
        {
            $DriftSummary += Write-Output "CURRENT: $CurrentMethod authentication method state is $($CloudAuthenticationMethodConfiguration.State) -> DESIRED: Setting should be $ParamState"
        }
    }
    else
    {
        $DriftSummary += Write-Output "No drift detected. The current state aligns with the desired state." 
    }

    $DriftSummary | foreach { Write-Host $_}
    
    Write-Host "===================================================================================================="

    # Summarize current state
    if($Iteration -gt 0) {
        Write-Host "--------------- Current State of $CurrentMethod Authentication Method After Changes ---------------"
    }
    else {
        Write-Host "--------------- Current State of $CurrentMethod Authentication Method Before Changes ---------------"
    }
    Write-Host "AUTHENTICATION METHOD STATE:"
    Write-Host "`tCurrent state of authentication method $CurrentMethod is" $CloudAuthenticationMethodConfiguration.State
    Write-Host "ADDITIONAL PROPERTIES:"
    Write-Host "`tInclude Target Object IDs: "
    $($CloudIncludeTargets.id) | foreach { Write-Host `t`t$_ }
    Write-Host "`tAllowExternalIdToUseEmailOtp : " $CloudAuthenticationMethodConfiguration.AdditionalProperties.allowExternalIdToUseEmailOtp
    
    Write-Host "===================================================================================================="
    if($DriftCounter -gt 0)
    {
        Write-Host "DRIFT DETECTED: The current state does not align with the desired state."
    }
    else
    {
        Write-Host "NO DRIFT DETECTED: The current state aligns with the desired state."
    }
    Write-Host "===================================================================================================="

    $Iteration += 1
    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
    
}