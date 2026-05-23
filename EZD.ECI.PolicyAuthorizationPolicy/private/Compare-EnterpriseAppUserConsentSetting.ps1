function Compare-EnterpriseAppUserConsentSetting {

    # Compile the current state of the setting
    Write-Host "Now compiling current state of Enterprise App User Consent settings."
    $PolicyAuthorizationPolicy = Get-MgPolicyAuthorizationPolicy
    $CurrentUserConsentSettings = $PolicyAuthorizationPolicy.DefaultUserRolePermissions.PermissionGrantPoliciesAssigned
        
    $IsAllowedFromVerifiedPublishers = $CurrentUserConsentSettings -Contains "ManagePermissionGrantsForSelf.microsoft-user-default-low"
    $IsAllowedAll = $CurrentUserConsentSettings -Contains "ManagePermissionGrantsForSelf.microsoft-user-default-legacy"

    $CurrentMappedSettings = @{
        AllowFromVerifiedPublishers = $IsAllowedFromVerifiedPublishers
        AllowAll = $IsAllowedAll
        DoNotAllow = (-Not $IsAllowedFromVerifiedPublishers) -And (-Not $IsAllowedAll)
    }

    $CurrentlyEnabledSetting = ($CurrentMappedSettings.GetEnumerator() | Where-Object {$_.Value -eq $true}).Key
    
    # Calculate drift of the current state from the desired state
    Write-Host "Now evaluating alignment of Enterprise App Consent Settings with desired state."
    $DriftCounter = 0
    if ($DesiredConsentSetting -ne $CurrentlyEnabledSetting)
    {
        Write-Host "Enterprise App Consent Settings do not align with the desired state. It should be set to: $DesiredConsentSetting"
        $DriftCounter += 1
    }
    elseif ($CurrentAllowedUserRolePermission -eq $UserRolePermissionIsAllowed) 
    {
        Write-Host "Enterprise App Consent Settings align with the desired state ($DesiredConsentSetting). No change is necessary."
    }
    else 
    {
		Write-Host "WARNING: Configuration for Enterprise App Consent Settings could not be retrieved."
		$ReturnCode = 1
	}

    Write-Host "----------------------------------------------------------------------------------------------------"
    
    # Summarize drift
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        if ($DesiredConsentSetting -ne $CurrentlyEnabledSetting)
        {
            $DriftSummary += Write-Output "CURRENT: Enterprise App Consent Settings is $CurrentlyEnabledSetting -> DESIRED: Setting value should be $DesiredConsentSetting"
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
        Write-Host "----------------- Current State of Enterprise App Consent Settings After Changes -------------------"
    }
    else {
        Write-Host "----------------- Current State of Enterprise App Consent Settings Before Changes ------------------"
    }
    $MappedSettingList = $CurrentMappedSettings.Keys
    foreach($Setting in $MappedSettingList)
    {
        $SettingValue = $CurrentMappedSettings.$Setting
        Write-Host "$Setting : $SettingValue"
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
    
    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "ReturnCode" = $ReturnCode; "CurrentlyEnabledSetting" = $CurrentlyEnabledSetting; "CurrentUserConsentSettings" = $CurrentUserConsentSettings; "DriftSummary" = $DriftSummary }

}