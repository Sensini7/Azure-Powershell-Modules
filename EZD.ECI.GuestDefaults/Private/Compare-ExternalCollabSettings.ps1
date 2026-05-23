function Compare-GuestDefaults {

    # Define the setting list and drift counter
    $SettingList = "GuestUserRoleIdGuid", "AllowInvitesFrom", "AllowSelfServiceSignup", "AllowExternalIdentitiesToLeave"
    $DriftCounter = 0

    # Compile the current cloud settings
    $CloudGuestUserRoleIdGuid = Get-MgPolicyAuthorizationPolicy | Select -ExpandProperty GuestUserRoleId
    $CloudAllowInvitesFrom = Get-MgPolicyAuthorizationPolicy | Select -ExpandProperty AllowInvitesFrom
    $CloudAllowSelfServiceSignup = (Get-MgBetaPolicyAuthenticationFlowPolicy).SelfServiceSignUp.IsEnabled
    $CloudAllowExternalIdentitiesToLeave = Get-MgBetaPolicyExternalIdentityPolicy | Select -ExpandProperty AllowExternalIdentitiesToLeave

    # Calculate drift of the current state from the desired state
    Write-Host "Now evaluating each external collaboration setting for drift of the current configuration from the desired configuration."
    $DriftCounter = 0
    ForEach($Setting in $SettingList)
    {
        $SettingValue = Get-Variable -Name $Setting -ValueOnly
        $CloudSettingValue = Get-Variable -Name "Cloud$Setting" -ValueOnly
        if($SettingValue -ne $CloudSettingValue)
        {
            Write-Host "$Setting is not configured with expected value. It should be set with value $SettingValue."
            $DriftCounter += 1
        }
        elseif($SettingValue -eq $CloudSettingValue)
        {
            Write-Host "$Setting is configured with expected value ($SettingValue). No need to perform any changes."
        }
        else
        {
            Write-Host "WARNING: The external collaboration settings could not be retrieved."
		    $ReturnCode = 1
        }
    }
    Write-Host "----------------------------------------------------------------------------------------------------"
    
    # Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        ForEach($Setting in $SettingList)
        {
            $SettingValue = Get-Variable -Name $Setting -ValueOnly
            $CloudSettingValue = Get-Variable -Name "Cloud$Setting" -ValueOnly
            if($SettingValue -ne $CloudSettingValue)
            {
                $DriftSummary += Write-Output "CURRENT: $Setting value is $CloudSettingValue -> DESIRED: Setting value should be $SettingValue"
            }
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
        Write-Host "----------------- Current State of External Collaboration Settings After Changes -------------------"
    }
    else {
        Write-Host "----------------- Current State of External Collaboration Settings Before Changes ------------------"
    }
    ForEach($Setting in $SettingList)
    {
        $CloudSettingValue = Get-Variable -Name "Cloud$Setting" -ValueOnly
        Write-Host "$Setting : $CloudSettingValue"
    }

    $Iteration += 1

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

    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "ReturnCode" = $ReturnCode; "DriftSummary" = $DriftSummary }

}