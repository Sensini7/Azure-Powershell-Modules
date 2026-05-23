function Compare-TemporaryAccessPassAuthMethod {

    # Evaluate drift of non-array settings specific to the authentication method
    $SettingList = @("defaultLifetimeInMinutes","defaultLength","minimumLifetimeInMinutes","maximumLifetimeInMinutes","isUsableOnce")

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
            Write-Host "$Setting is configured with expected value ($SettingValue). No need to perform any changes."
        }
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
        ForEach($Setting in $SettingList)
        {
            $SettingValue = Get-Variable -Name $Setting -ValueOnly
            $CloudSettingValue = $CloudAuthenticationMethodConfiguration.AdditionalProperties.$Setting
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