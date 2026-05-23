function Compare-X509CertificateAuthMethod {
          
    ### Validate settings alignment ###
    # Compile current AuthenticationMode settings
    $CloudAuthenticationModeConfiguration = $CloudAuthenticationMethodConfiguration.AdditionalProperties.authenticationModeConfiguration
    $CloudX509CertificateAuthenticationDefaultMode = $CloudAuthenticationModeConfiguration.x509CertificateAuthenticationDefaultMode
    $CloudX509CertificateDefaultRequiredAffinityLevel = $CloudAuthenticationModeConfiguration.x509CertificateDefaultRequiredAffinityLevel
                
    # Compile current AuthenticationMode rules
    $CloudAuthenticationModeRules = $CloudAuthenticationModeConfiguration.rules
    $CloudAuthenticationModeRuleSummary = @()
    foreach($CloudAuthenticationModeRule in $CloudAuthenticationModeRules)
    {
        $CloudAuthenticationModeRuleSettings = @{
            "CloudIdentifier" = $CloudAuthenticationModeRule.identifier
            "Cloudx509CertificateRuleType" = $CloudAuthenticationModeRule.x509CertificateRuleType
            "Cloudx509CertificateAuthenticationMode" = $CloudAuthenticationModeRule.x509CertificateAuthenticationMode
            "Cloudx509CertificateRequiredAffinityLevel" = $CloudAuthenticationModeRule.x509CertificateRequiredAffinityLevel
            "Cloudx509CertificateUniqueId" = $CloudAuthenticationModeRule.x509CertificateRuleType+":"+$CloudAuthenticationModeRule.identifier
            "Cloudx509CertificateAuthenticationModeHash" = $CloudAuthenticationModeRule.x509CertificateRuleType+":"+$CloudAuthenticationModeRule.identifier+":"+$CloudAuthenticationModeRule.x509CertificateAuthenticationMode
            "Cloudx509CertificateRequiredAffinityLevelHash" = $CloudAuthenticationModeRule.x509CertificateRuleType+":"+$CloudAuthenticationModeRule.identifier+":"+$CloudAuthenticationModeRule.x509CertificateRequiredAffinityLevel
        }
        $CloudAuthenticationModeRuleSummary += $CloudAuthenticationModeRuleSettings
    }
                
    # Compile current certificate user binding settings
    $CloudCertificateUserBindings = $CloudAuthenticationMethodConfiguration.AdditionalProperties.certificateUserBindings
    $CloudCertificateUserBindingSummary = @()
    foreach($CloudCertificateUserBinding in $CloudCertificateUserBindings)
    {
        $CloudCertificateUserBindingSettings = @{
            "CloudX509CertificateField" = $CloudCertificateUserBinding.x509CertificateField
            "CloudUserProperty" = $CloudCertificateUserBinding.userProperty
            "CloudUserPropertyHash" = $CloudCertificateUserBinding.x509CertificateField+":"+$CloudCertificateUserBinding.userProperty
            "CloudPriorityHash" = $CloudCertificateUserBinding.x509CertificateField+":"+$CloudCertificateUserBinding.priority
        }
        $CloudCertificateUserBindingSummary += $CloudCertificateUserBindingSettings
    }

    Write-Host "----------------------------------------------------------------------------------------------------"

    # Validate whether current AuthenticationMode settings align with desired settings
    Write-Host "Now evaluating X509 AuthenticationMode settings."
    if ($CloudX509CertificateAuthenticationDefaultMode -ne $X509CertificateAuthenticationDefaultMode)
    {
        Write-Host "X509 certificate authentication default mode is not configured as expected."
        Write-Host "X509 certificate authentication default mode should be configured with setting $X509CertificateAuthenticationDefaultMode."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "X509 certificate authentication default mode is configured as expected. No change to this setting is necessary."
    }

    if ($CloudX509CertificateDefaultRequiredAffinityLevel -ne $X509CertificateDefaultRequiredAffinityLevel)
    {
        Write-Host "X509 certificate default required affinity level is not configured as expected."
        Write-Host "X509 certificate default required affinity level should be configured with setting $X509CertificateDefaultRequiredAffinityLevel."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "X509 certificate default required affinity level is configured as expected. No change to this setting is necessary."
    }

    Write-Host "----------------------------------------------------------------------------------------------------"

    # Validate whether current AuthenticationMode rules align with desired settings
    Write-Host "Now evaluating authentication mode rule settings."
    $RulesToRemove = @()
    $RulesToAdd = @()
    $RulesToModify = @()
    foreach($CloudAuthenticationModeRule in $CloudAuthenticationModeRuleSummary)
    {
        $Cloudx509CertificateRuleType = $CloudAuthenticationModeRule.Cloudx509CertificateRuleType
        $CloudIdentifier = $CloudAuthenticationModeRule.CloudIdentifier
        $Cloudx509CertificateUniqueId = $CloudAuthenticationModeRule.Cloudx509CertificateUniqueId
        if($AuthenticationModeRuleSummary.x509CertificateUniqueId -NotContains $Cloudx509CertificateUniqueId)
        {
            Write-Host "Rule with ID $CloudIdentifier and type $Cloudx509CertificateRuleType is deployed but not listed in the desired state. It should be removed."
            $RulesToRemove += $Cloudx509CertificateUniqueId
            $DriftCounter += 1
        }
    }
    if($RulesToRemove.Count -eq 0)
    {
        Write-Host "There are no authentication mode rules configured in the tenant which are not in the desired state. No change is necessary."
    }

    foreach($AuthenticationModeRule in $AuthenticationModeRuleSummary)
    {
        $Identifier = $AuthenticationModeRule.Identifier
        $X509CertificateRuleType = $AuthenticationModeRule.x509CertificateRuleType
        $X509CertificateUniqueId = $AuthenticationModeRule.x509CertificateUniqueId
        $X509CertificateAuthenticationMode = $AuthenticationModeRule.x509CertificateAuthenticationMode
        $X509CertificateRequiredAffinityLevel = $AuthenticationModeRule.x509CertificateRequiredAffinityLevel
        $X509CertificateUniqueId = $AuthenticationModeRule.x509CertificateUniqueId
        $X509CertificateAuthenticationModeHash = $AuthenticationModeRule.x509CertificateAuthenticationModeHash
        $X509CertificateRequiredAffinityLevelHash = $AuthenticationModeRule.x509CertificateRequiredAffinityLevelHash
        Write-Host "Now evaluating configuration of X509 authentication rule with ID $Identifier."
        if($CloudAuthenticationModeRuleSummary.Cloudx509CertificateUniqueId -Contains $X509CertificateUniqueId)
        {
            if(($CloudAuthenticationModeRuleSummary.Cloudx509CertificateAuthenticationModeHash -Contains $X509CertificateAuthenticationModeHash) -and ($CloudAuthenticationModeRuleSummary.Cloudx509CertificateRequiredAffinityLevelHash -Contains $X509CertificateRequiredAffinityLevelHash))
            {
                Write-Host "X509 rule with ID $Identifier is correct. No change is necessary."
            }
            else
            {
                if(($CloudAuthenticationModeRuleSummary.Cloudx509CertificateAuthenticationModeHash -NotContains $X509CertificateAuthenticationModeHash) -and ($CloudAuthenticationModeRuleSummary.Cloudx509CertificateRequiredAffinityLevelHash -NotContains $X509CertificateRequiredAffinityLevelHash))
                {
                    Write-Host "X509 rule with ID $Identifier has an incorrect authentication mode and required affinity level."
                    Write-Host "Rule should be configured with authentication mode $X509CertificateAuthenticationMode and required affinity level $X509CertificateRequiredAffinityLevel."
                    $RulesToModify += $X509CertificateUniqueId
                    $DriftCounter += 1
                }
                elseif($CloudAuthenticationModeRuleSummary.Cloudx509CertificateAuthenticationModeHash -NotContains $X509CertificateAuthenticationModeHash)
                {
                    Write-Host "X509 rule with ID $Identifier has an incorrect authentication mode."
                    Write-Host "Rule should be configured with authentication mode $X509CertificateAuthenticationMode."
                    $RulesToModify += $X509CertificateUniqueId
                    $DriftCounter += 1
                }
                elseif($CloudAuthenticationModeRuleSummary.Cloudx509CertificateRequiredAffinityLevelHash -NotContains $X509CertificateRequiredAffinityLevelHash)
                {
                    Write-Host "X509 rule with ID $Identifier has an incorrect required affinity level."
                    Write-Host "Rule should be configured with required affinity level $X509CertificateRequiredAffinityLevel."
                    $RulesToModify += $X509CertificateUniqueId
                    $DriftCounter += 1
                }
                else
                {
                    Write-Host "ERROR: Failed to evaluate if X509 authentication rule with ID $Identifier is properly configured."
                    $RulesToAdd += $X509CertificateUniqueId
                    return 1
                }
            }
        }
        else
        {
            Write-Host "X509 authentication rule with ID $Identifier is not present in tenant."
            Write-Host "X509 authentication rule with ID $Identifier should be configured with authentication mode $X509CertificateAuthenticationMode and required affinity level $X509CertificateRequiredAffinityLevel."
            $RulesToAdd += $X509CertificateUniqueId
            $DriftCounter += 1
        }
    }

    Write-Host "----------------------------------------------------------------------------------------------------"

    # Validate whether certificate user binding settings align with desired settings
    Write-Host "Now evaluating X509 certificate user binding settings."
    $BindingSettingsToAdd = @()
    $BindingSettingsToRemove = @()
    $BindingSettingsToAdd = @()

    foreach($CloudCertificateUserBinding in $CloudCertificateUserBindingSummary)
    {
        $CloudX509CertificateField = $CloudCertificateUserBinding.CloudX509CertificateField
        $CloudUserProperty = $CloudCertificateUserBinding.CloudUserProperty
        $CloudUserPropertyHash = $CloudCertificateUserBinding.CloudUserPropertyHash
        if($CertificateUserBindingSummary.UserPropertyHash -NotContains $CloudUserPropertyHash)
        {
            Write-Host "Certificate user binding [$CloudX509CertificateField : $CloudUserProperty] in format [X509Field : UserProperty] is not in the desired state. It should be removed."
            $BindingSettingsToRemove += $CloudUserPropertyHash
            $DriftCounter += 1
        }
    }
    if($BindingSettingsToRemove.Count -eq 0)
    {
        Write-Host "There are no certificate user binding settings configured in the tenant which are not in the desired state. No change is necessary."
    }

    foreach($CertificateUserBinding in $CertificateUserBindingSummary)
    {
        $X509CertificateField = $CertificateUserBinding.X509CertificateField
        $UserProperty = $CertificateUserBinding.UserProperty
        $Priority = $CertificateUserBinding.Priority
        $UserPropertyHash = $CertificateUserBinding.UserPropertyHash
        $PriorityHash = $CertificateUserBinding.PriorityHash
        Write-Host "Now evaluating configuration of X509CertificateField $X509CertificateField."
        if($CloudCertificateUserBindingSummary.CloudX509CertificateField -Contains $X509CertificateField)
        {
            if(($CloudCertificateUserBindingSummary.CloudUserPropertyHash -Contains $UserPropertyHash) -and ($CloudCertificateUserBindingSummary.CloudPriorityHash -Contains $PriorityHash))
            {
                Write-Host "Certificate user binding settings for X509 certificate attribute $X509CertificateField are correct. No change is necessary to settings for this attribute."
            }
            else
            {
                if(($CloudCertificateUserBindingSummary.CloudUserPropertyHash -NotContains $UserPropertyHash) -and ($CloudCertificateUserBindingSummary.CloudPriorityHash -NotContains $PriorityHash))
                {
                    Write-Host "X509 certificate attribute $X509CertificateField is configured but has an incorrect user attribute mapping and priority configured."
                    Write-Host "X509 certificate attribute $X509CertificateField should be configured with user attribute mapping $UserProperty and priority $Priority."
                    $BindingSettingsToAdd += $UserPropertyHash
                    $DriftCounter += 1
                }
                elseif($CloudCertificateUserBindingSummary.CloudUserPropertyHash -NotContains $UserPropertyHash)
                {
                    Write-Host "X509 certificate attribute $X509CertificateField is configured but has an incorrect user attribute mapping configured."
                    Write-Host "X509 certificate attribute $X509CertificateField should be configured with user attribute mapping $UserProperty."
                    $BindingSettingsToAdd += $UserPropertyHash
                    $DriftCounter += 1
                }
                elseif($CloudCertificateUserBindingSummary.CloudPriorityHash -NotContains $PriorityHash)
                {
                    Write-Host "X509 certificate attribute $X509CertificateField is configured but has an incorrect priority configured."
                    Write-Host "X509 certificate attribute $X509CertificateField should be configured with priority $Priority."
                    $BindingSettingsToModify += $UserPropertyHash
                    $DriftCounter += 1
                }
                else
                {
                    Write-Host "ERROR: Failed to evaluate if $X509CertificateField is properly configured."
                    $BindingSettingsToAdd += $UserPropertyHash
                    return 1
                }
            }
        }
        else
        {
            Write-Host "X509 certificate attribute $X509CertificateField is not present in tenant."
            Write-Host "X509 certificate attribute $X509CertificateField should be configured with user attribute mapping $UserProperty and priority $Priority."
            $BindingSettingsToAdd += $UserPropertyHash
            $DriftCounter += 1
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
        if ($CloudX509CertificateAuthenticationDefaultMode -ne $X509CertificateAuthenticationDefaultMode)
        {
            $DriftSummary += Write-Output "CURRENT: Authentication default mode is $CloudX509CertificateAuthenticationDefaultMode -> DESIRED: Setting should be $X509CertificateAuthenticationDefaultMode"
        }
        if ($CloudX509CertificateDefaultRequiredAffinityLevel -ne $X509CertificateDefaultRequiredAffinityLevel)
        {
            $DriftSummary += Write-Output "CURRENT: Authentication mode required affinity mode is $CloudX509CertificateDefaultRequiredAffinityLevel -> DESIRED: Setting should be $X509CertificateDefaultRequiredAffinityLevel"
        }
        if($RulesToAdd.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Authentication mode rules are missing from current state -> DESIRED: These should be added, listed in format [Type : ID]:"
            $RulesToAdd | foreach { $DriftSummary += Write-Output `t"[$_]" }
        }
        if($RulesToModify.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Authentication mode rules are improperly configured in the tenant -> DESIRED: These should be modified, listed in format [Type : ID]:"
            $RulesToModify | foreach { $DriftSummary += Write-Output `t"[$_]" }
        }
        if($RulesToRemove.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Authentication mode rules are in the tenant which are not in the desired state -> DESIRED: These should be removed, listed in format [Type : ID]:"
            $RulesToRemove | foreach { $DriftSummary += Write-Output `t"[$_]" }
        }
        if($BindingSettingsToAdd.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Username bindings are missing from current state -> DESIRED: These should be added, listed in format [X509Field : UserProperty]:"
            $BindingSettingsToAdd | foreach { $DriftSummary += Write-Output `t"[$_]" }
        }
        if($BindingSettingsToModify.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Username bindings are improperly configured in the tenant -> DESIRED: These should be modified, listed in format [X509Field : UserProperty]:"
            $BindingSettingsToModify | foreach { $DriftSummary += Write-Output `t"[$_]" }
        }
        if($BindingSettingsToRemove.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Username bindings are deployed which are not in the desired state -> DESIRED: These should be removed, listed in format [X509Field : UserProperty]:"
            $BindingSettingsToRemove | foreach { $DriftSummary += Write-Output `t"[$_]" }
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
    Write-Host "INCLUDE TARGETS:"
    Write-Host "`tInclude Target Object IDs: "
    $($CloudIncludeTargets.id) | foreach { Write-Host `t`t$_ }
    Write-Host "AUTHENTICATION MODE SETTINGS:"
    Write-Host "`tx509CertificateAuthenticationDefaultMode:" $CloudAuthenticationMethodConfiguration.AdditionalProperties.authenticationModeConfiguration.x509CertificateAuthenticationDefaultMode
    Write-Host "`tx509CertificateDefaultRequiredAffinityLevel:" $CloudAuthenticationMethodConfiguration.AdditionalProperties.authenticationModeConfiguration.x509CertificateDefaultRequiredAffinityLevel
    Write-Host "AUTHENTICATION MODE RULES:"
    $Counter = 1
    foreach($Rule in $CloudAuthenticationModeRules) {
        Write-Host "`tSettings for authentication mode rule $Counter :"
        foreach($Key in $Rule.Keys) {
            Write-Host "`t`t$Key : $($Rule.$Key)"
        }
        $Counter += 1
    }
    Write-Host "CERTIFICATE USER BINDINGS:"
    $Counter = 1
    foreach($Binding in $CloudCertificateUserBindings) {
        Write-Host "`tSettings for certificate user binding setting $Counter :"
        foreach($Key in $Binding.Keys) {
            Write-Host "`t`t$Key : $($Binding.$Key)"
        }
        $Counter += 1
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
    return @{ "Iteration" = $Iteration; "CloudCertificateUserBindingSummary" = $CloudCertificateUserBindingSummary; "CloudAuthenticationModeRuleSummary" = $CloudAuthenticationModeRuleSummary; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
    
}