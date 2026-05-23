function Compare-PasswordProtection {
    
    # Evaluate current state for drift from desired state
    $DriftCounter = 0
    $PasswordRuleSettings = (Get-MgBetaDirectorySetting | Where-Object { $_.DisplayName -eq "Password Rule Settings" }).Values
    if(!$PasswordRuleSettings)
    {
        Write-Host "The password protection policy object has not been initiated in the tenant. It should be created and configured with desired settings."
        $DriftCOunter += 1
    }
    else
    {
        foreach($Setting in $params.values)
        {
            $SettingName = $Setting.Name
            $SettingValue = $Setting.Value
            $CloudSettingValue = ($PasswordRuleSettings | Where-Object { $_.Name -eq $SettingName }).Value
            if($SettingValue -eq $CloudSettingValue)
            {
                Write-Host "Current configuration of setting $SettingName aligns with the desired state ($SettingValue). No change is necessary."
            }
            elseif($SettingName -eq "BannedPasswordList")
            {
                $BannedPasswordListStandard = ($SettingValue -replace '\s+',' ').Split(" ")
                $CloudBannedPasswordListStandard = ($CloudSettingValue -replace '\s+',' ').Split(" ")
                $CombinedMissingPasswordList = @()

                # Determine if any passwords in the current password list are not in the desired list and should be removed
                $RemovePasswordList = @()
                foreach($CloudBannedPassword in $CloudBannedPasswordListStandard)
                {
                    if($BannedPasswordListStandard -NotContains $CloudBannedPassword)
                    {
                        $RemovePasswordList += $CloudBannedPassword
                        $DriftCounter += 1
                    }
                }
                if($RemovePasswordList.Count -gt 0)
                {
                    Write-Host "The following passwords are in the current banned password list but are not in the desired banned password list. They should be removed."
                    $RemovePasswordList | foreach { Write-Host "`t"$_ }
                    $CombinedMissingPasswordList += $RemovePasswordList
                }
                else
                {
                    Write-Host "There are no passwords in the current banned password list which are not present in the desired banned password list."
                }
                
                # Determine if any passwords in the desired password list are not in the current list and should be added
                $AddPasswordList = @()
                foreach($BannedPassword in $BannedPasswordListStandard)
                {
                    if($CloudBannedPasswordListStandard -NotContains $BannedPassword)
                    {
                        $AddPasswordList += $BannedPassword
                        $DriftCounter += 1
                    }
                }
                if($AddPasswordList.Count -gt 0)
                {
                    Write-Host "The following passwords are in the desired banned password list but are not in the current banned password list. They should be added."
                    $AddPasswordList | foreach { Write-Host "`t"$_ }
                    $CombinedMissingPasswordList += $AddPasswordList
                }
                else
                {
                    Write-Host "There are no passwords in the desired banned password list which are not present in the current banned password list."
                }

                # Display a log message if there are no misconfigured applications
                if($CombinedMissingPasswordList.Count -eq 0)
                {
                    Write-Host "The banned password list is configured as expected. No change is necessary."
                }
            }
            else
            {
                Write-Host "Current configuration of setting $SettingName does not align with the desired state. It should be set to $SettingValue."
                $DriftCounter += 1
            }
        }
    }

    Write-Host "-----------------------------------------------------------------------------------------------------"

    # Summarize detected drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        if(!$PasswordRuleSettings)
        {
            $DriftSummary += Write-Output "CURRENT: The password protection policy object is not initiated -> DESIRED: It should be created and configured with these settings:"
            foreach($Setting in $params.values)
            {
                $SettingName = $Setting.Name
                $SettingValue = $Setting.Value
                $SettingValueStandard = $SettingValue -replace '\s+',' '
                $DriftSummary += Write-Output "`t$SettingName : $SettingValueStandard"
            }
        }
        else
        {
            foreach($Setting in $params.values)
            {
                $SettingName = $Setting.Name
                $SettingValue = $Setting.Value
                $CloudSettingValue = ($PasswordRuleSettings | Where-Object { $_.Name -eq $SettingName }).Value
                if(($SettingValue -ne $CloudSettingValue) -and ($SettingName -eq "BannedPasswordList"))
                {
                    if($AddPasswordList.Count -gt 0)
                    {
                        $DriftSummary += Write-Output "CURRENT: Passwords in the desired state are missing from the current banned password list -> DESIRED: Add these passwords to the list:"
                        $AddPasswordList | foreach { $DriftSummary += Write-Output "`t$_" }
                        $CombinedMissingPasswordList += $AddPasswordList
                    }
                    elseif(($SettingValue -ne $CloudSettingValue) -and ($SettingName -ne "BannedPasswordList"))
                    {
                        $DriftSummary += Write-Output "CURRENT: $SettingName value is $CloudSettingValue -> DESIRED: Setting value should be $SettingValue"
                    }

                    if($RemovePasswordList.Count -gt 0)
                    {
                        $DriftSummary += Write-Output "CURRENT: Passwords in the current banned password list are not in the desired state -> DESIRED: Remove these passwords from the list:"
                        $RemovePasswordList | foreach { $DriftSummary += Write-Output "`t$_" }
                    }
                }
                elseif(($SettingValue -ne $CloudSettingValue) -and ($SettingName -ne "BannedPasswordList"))
                {
                    $DriftSummary += Write-Output "CURRENT: $SettingName value is $CloudSettingValue -> DESIRED: Setting value should be $SettingValue"
                }
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
        Write-Host "------------------ Current State of Password Protection Settings After Changes -------------------"
    }
    else {
        Write-Host "------------------ Current State of Password Protection Settings Before Changes ------------------"
    }
    foreach($Setting in $PasswordRuleSettings)
    {
        $CloudSettingName = $Setting.Name
        $CloudSettingValue = $Setting.Value
        $CloudSettingValueStandard = $CloudSettingValue -replace '\s+',' '
        Write-Host $CloudSettingName":" $CloudSettingValueStandard
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

    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }

}