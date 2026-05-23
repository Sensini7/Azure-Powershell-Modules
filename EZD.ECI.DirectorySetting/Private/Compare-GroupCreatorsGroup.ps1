function Compare-GroupCreatorsGroup {

    $DriftCounter = 0
    # Compile current state settings
    if(!$DirectorySettingObjectId)
    {
        if($GroupCreationAllowedGroupId)
        {
            Write-Host "Group creation setting object does not exist. It should be created with the following settings."
            Write-Host "Group creation setting:" $EnableGroupCreationForAllUsers
            Write-Host "Group creators group object ID:" $GroupCreationAllowedGroupId
        }
        else
        {
            Write-Host "Group creation setting object does not exist. It should be created with the following settings."
            Write-Host "Group creation setting:" $EnableGroupCreationForAllUsers
            Write-Host "Group creators group object ID: Group Creators Group does not exist and must be created"
        }
        $DriftCounter += 1
    }
    else
    {
        $CurrentEnableGroupCreationSetting = (Get-MgBetaDirectorySetting -DirectorySettingId $DirectorySettingObjectId).Values | Where {$_.Name -eq "EnableGroupCreation"} 
        $CurrentCreationAllowedGroupId = (Get-MgBetaDirectorySetting -DirectorySettingId $DirectorySettingObjectId).Values | Where {$_.Name -eq "GroupCreationAllowedGroupId" -and $_.Value}
        
        $GroupCreationIsCorrect = $CurrentEnableGroupCreationSetting.Value -eq $EnableGroupCreationForAllUsers
        $GroupCreationAllowedGroupIdIsCorrect = $CurrentCreationAllowedGroupId.Value -eq $GroupCreationAllowedGroupId

        # Calculate drift of the current state from the desired state 
        if ($GroupCreationIsCorrect -and $GroupCreationAllowedGroupIdIsCorrect) {
            Write-Host "Group creation setting is configured with the desired setting ($EnableGroupCreationForAllUsers)."
            Write-Host "Group creators group setting is configured to the desired group with object ID $GroupCreationAllowedGroupId."
        } else {
            if ((!$GroupCreationIsCorrect) -and (!$GroupCreationAllowedGroupIdIsCorrect)) {
                Write-Host "Both EnableGroupCreation and GroupCreationAllowedGroupId are misconfigured."
                Write-Host "Directory EnableGroupCreation (for all users) settings should be updated from $($CurrentEnableGroupCreationSetting.Value) to $EnableGroupCreationForAllUsers"
                Write-Host "Directory GroupCreationAllowedGroupId settings should be updated from $($CurrentCreationAllowedGroupId.Value) to $GroupCreationAllowedGroupId"
                $DriftCounter += 1
            } elseif (!$GroupCreationIsCorrect) {
                Write-Host "Directory EnableGroupCreation (for all users) settings should be updated from $($CurrentEnableGroupCreationSetting.Value) to $EnableGroupCreationForAllUsers"
                $DriftCounter += 1
            } elseif (!$GroupCreationAllowedGroupIdIsCorrect) {
                Write-Host "Directory GroupCreationAllowedGroupId settings should be updated from $($CurrentCreationAllowedGroupId.Value) to $GroupCreationAllowedGroupId"
                $DriftCounter += 1
            } else {
                Write-Host "WARNING: Unable to validate group creation settings."
                $ReturnVariable = 1
            }
        }
    }

    Write-Host "----------------------------------------------------------------------------------------------------"

    ### Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        if(!$DirectorySettingObjectId)
        {
            if($GroupCreationAllowedGroupId)
            {
                $DriftSummary += Write-Output "CURRENT: Group creation setting object does not exist -> DESIRED: Create setting object and configure the following settings:"
                $DriftSummary += Write-Output "`tEnableGroupCreation: $EnableGroupCreationForAllUsers"
                $DriftSummary += Write-Output "`tGroupCreationAllowedGroupId: $GroupCreationAllowedGroupId"
            }
            else
            {
                $DriftSummary += Write-Output "CURRENT: Group creation setting object does not exist; there are no restrictions on Microsoft 365 Group Creation -> DESIRED: Create setting object and set EnableGroupCreation setting to $EnableGroupCreationForAllUsers"
            }
        }
        elseif(!$GroupCreationIsCorrect)
        {
            $DriftSummary += Write-Output "CURRENT: EnableGroupCreation setting is $($CurrentEnableGroupCreationSetting.Value) -> DESIRED: Setting should be set to $EnableGroupCreationForAllUsers"
        }

        if(!$GroupCreationAllowedGroupId)
        {
            $DriftSummary += Write-Output "CURRENT: Group Creation Group does not exist -> DESIRED: Create a new Group Creation Group and specify it EnableGroupCreation setting"
        }
        elseif(!$GroupCreationAllowedGroupIdIsCorrect -and $DirectorySettingObjectId)
        {
            $DriftSummary += Write-Output "CURRENT: GroupCreationAllowedGroupId setting is $($CurrentCreationAllowedGroupId.Value) -> DESIRED: Setting should be set to $GroupCreationAllowedGroupId"
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
        Write-Host "------------------- Current State of Group Creation Group Settings After Changes -------------------"
    }
    else {
        Write-Host "------------------- Current State of Group Creation Group Settings Before Changes ------------------"
    }
    
    if(!$DirectorySettingObjectId)
    {
        Write-Host "Group creation setting object does not exist. All non-privileged users are currently able to create groups of type Microsoft 365 Group."
    }
    else
    {
        $GroupCreationSettingSummary = (Get-MgBetaDirectorySetting -DirectorySettingId $DirectorySettingObjectId).Values | Where {$_.Name -eq "EnableGroupCreation" -or $_.Name -eq "GroupCreationAllowedGroupId"}
        foreach($Setting in $GroupCreationSettingSummary)
        {
            $SettingName = $Setting.Name
            $SettingValue = $Setting.Value
            Write-Host $SettingName":" $SettingValue
        }
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