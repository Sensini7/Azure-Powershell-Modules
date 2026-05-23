function Compare-Fido2AuthMethod {

    Write-Host "===================================================================================================="

    # Evaluate drift of non-array settings specific to the authentication method
    $SettingList = @("isSelfServiceRegistrationAllowed","isAttestationEnforced")
    $CloudaaGuids = $CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.aaGuids
    $aaGuidsToAdd = @()
    $aaGuidsToRemove = @()

    Write-Host "Now evaluating each setting specific to authentication method $CurrentMethod for drift of the current configuration from the desired configuration."
    ForEach($Setting in $SettingList)
    {
        $SettingValue = Get-Variable -Name $Setting -ValueOnly
        if($SettingValue -ne $CloudAuthenticationMethodConfiguration.AdditionalProperties.$Setting)
        {
            Write-Host "$Setting is not configured with expected value. It should be set with value $SettingValue."
            $DriftCounter += 1
        }
        else
        {
            Write-Host "$Setting is configured with expected value ($SettingValue). No change is necessary."
        }
    }

    # Evaluate drift of array settings specific to the authentication method
    Write-Host "----------------------------------------------------------------------------------------------------"

        foreach($aaGuid in $aaGuids)
    {
        if($CloudaaGuids -NotContains $aaGuid)
        {
            Write-Host "Authenticator attestation GUID $aaGuid is not present in the tenant. It should be added."
            $aaGuidsToAdd += $aaGuid
            $DriftCounter += 1
        }
    }
    if($aaGuidsToAdd.Count -eq 0)
    {
        Write-Host "There are no authenticator attestation GUIDs in the desired state which are missing from the tenant. This is expected. Proceeding."
    }

    foreach($CloudaaGuid in $CloudaaGuids)
    {
        if($aaGuids -NotContains $CloudaaGuid)
        {
            Write-Host "Authenticator attestation GUID $CloudaaGuid is configured but is not in the desired state. It should be removed."
            $aaGuidsToRemove += $CloudaaGuid
            $DriftCounter += 1
        }
    }
    if($aaGuidsToRemove.Count -eq 0)
    {
        Write-Host "There are no authenticator attestation GUIDs configured in the tenant which are not included in the desired GUIDs. This is expected. Proceeding."
    }

    if($isEnforced -ne $CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.isEnforced)
    {
        Write-Host "Key restriction enforcement state is not configured with expected value. It should be set with value $isEnforced."
        $DriftCounter += 1
    }
    else {
        Write-Host "Key restriction enforcement state is configured with the expected value ($isEnforced). No change is necessary."
    }

    if($enforcementType -ne $CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.enforcementType)
    {
        Write-Host "Key restriction enforcement type is not configured with expected value. It should be set with value $enforcementType."
        $DriftCounter += 1
    }
    else {
        Write-Host "Key restriction enforcement type is configured with the expected value ($enforcementType). No change is necessary."
    }
    
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
        # Display values of non-array settings specific to the authentication method
        foreach($Setting in $SettingList)
        {
            $SettingValue = Get-Variable -Name $Setting -ValueOnly
            $CloudSettingValue = $CloudAuthenticationMethodConfiguration.AdditionalProperties.$Setting
            if($SettingValue -ne $CloudSettingValue)
            {
                $DriftSummary += Write-Output "CURRENT: $Setting value is $CloudSettingValue -> DESIRED: Setting value should be $SettingValue"
            }
        }

        # Display key restriction setting drift
        if($aaguidsToAdd.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Authenticator attestation GUIDs are missing -> DESIRED: These GUIDs should be added:"
            $aaGuidsToAdd | foreach { $DriftSummary += Write-Output `t$_ }
        }
        if($aaguidsToRemove.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Authenticator attestation GUIDs include GUIDs which are not in the desired state -> DESIRED: These GUIDs should be removed:"
            $aaGuidsToRemove | foreach { $DriftSummary += Write-Output `t$_ }
        }

        if($isEnforced -ne $CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.isEnforced)
        {
            $DriftSummary += Write-Output "CURRENT: Key restriction enforcement state is $($CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.isEnforced) -> DESIRED: Setting value should be $isEnforced"
        }
    
        if($enforcementType -ne $CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.enforcementType)
        {
            $DriftSummary += Write-Output "CURRENT: Key restriction enforcement type is $($CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.enforcementType) -> DESIRED: Setting value should be $enforcementType."
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
    ForEach($Setting in $SettingList)
    {
        $CloudSettingValue = $CloudAuthenticationMethodConfiguration.AdditionalProperties.$Setting
        Write-Host "`t$Setting : $CloudSettingValue"
    }
    Write-Host "`tKey restriction settings: "
    Write-Host "`t`tAuthenticator attestation GUIDs:"
    $CloudaaGuids | foreach { Write-Host `t`t`t$_ }
    Write-Host "`t`tKey restriction enforcement state: " $CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.isEnforced
    Write-Host "`t`tKey restriction enforcement type: " $CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.enforcementType

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