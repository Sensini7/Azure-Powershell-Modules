function Compare-ActivityBasedTimeoutPolicy {

    # Compile the current state of the timeout
	if ($ActivityBasedTimeoutPolicy.Definition) {
        #$M365SessionidleTimeout = ($ActivityBasedTimeoutPolicy.definition | ConvertFrom-Json).ActivityBasedTimeoutPolicy.ApplicationPolicies | Where {$_.ApplicationId -eq "default"} | select -ExpandProperty WebSessionIdleTimeout
        $AzurePortalSessionidleTimeout = ($ActivityBasedTimeoutPolicy.definition | ConvertFrom-Json).ActivityBasedTimeoutPolicy.ApplicationPolicies | Where {$_.ApplicationId -eq $AzurePortalAppId} | select -ExpandProperty WebSessionIdleTimeout
        $CurrentPolicyDefinitions = ($ActivityBasedTimeoutPolicy.definition | ConvertFrom-Json).ActivityBasedTimeoutPolicy.ApplicationPolicies

        # Generate a policy hash to confirm that each application has the proper timeout setting
        $CurrentPolicyHashes = @()
        foreach($CurrentPolicyDefinition in $CurrentPolicyDefinitions)
        {
            $CurrentApplicationId = $CurrentPolicyDefinition.ApplicationId
            $CurrentWebSessionIdleTimeout = $CurrentPolicyDefinition.WebSessionIdleTimeout
            $CurrentPolicyHash = $CurrentApplicationId+"::"+$CurrentWebSessionIdleTimeout
            $CurrentPolicyHashes += $CurrentPolicyHash
        }
	}

    # Calculate drift of the current state from the desired state
    $DriftCounter = 0

    # Check if there are any missing or misconfigured policy definitions
    foreach($DesiredPolicyDefinition in $DesiredPolicyDefinitions)
    {
        $DesiredApplicationId = $DesiredPolicyDefinition.ApplicationId
        $DesiredWebSessionIdleTimeout = $DesiredPolicyDefinition.WebSessionIdleTimeout
        $DesiredPolicyHash = $DesiredApplicationId+"::"+$DesiredWebSessionIdleTimeout
        $DesiredPolicyHashes += $DesiredPolicyHash
        if($CurrentPolicyDefinitions.ApplicationId -NotContains $DesiredApplicationId)
        {
            Write-Host "An inactivity timeout setting for application with ID $DesiredApplicationId is not configured."
            Write-Host "A new inacitivity timeout setting should be configured for application with ID $DesiredApplicationId with timeout period $DesiredWebSessionIdleTimeout."
            $DriftCounter += 1
        }
        elseif(($CurrentPolicyDefinitions.ApplicationId -Contains $DesiredApplicationId) -and ($CurrentPolicyHashes -NotContains $DesiredPolicyHash))
        {
            Write-Host "An inactivity timeout setting for application with ID $DesiredApplicationId is configured but is set with an incorrect timeout period."
            Write-Host "The inacitivity timeout setting for application with ID $DesiredApplicationId to $DesiredWebSessionIdleTimeout."
            $DriftCounter += 1
        }
        elseif($CurrentPolicyHashes -Contains $DesiredPolicyHash)
        {
            Write-Host "Inactivity timeout application $DesiredApplicationId is configured with the desired timeout period ($DesiredWebSessionIdleTimeout). No change is necessary."
        }
        else {
            Write-Host "WARNING: The inactivity timeout settings could not be evaluated."
            $ReturnCode = 1
	    }
    }

    # Check if there are any existing policy definitions which should be removed
    $InvalidPolicies = @()
    foreach($CurrentPolicyDefinition in $CurrentPolicyDefinitions)
    {
        $CurrentApplicationId = $CurrentPolicyDefinition.ApplicationId
        if($DesiredPolicyDefinitions.ApplicationId -NotContains $CurrentApplicationId)
        {
            Write-Host "An inactivity timeout setting for application with ID $CurrentApplicationId is currently configured but is not included the desired state configuration."
            Write-Host "Inactivity timeout setting for application with ID $CurrentApplicationId should be removed."
            $DriftCounter += 1
            $InvalidPolicies += $CurrentApplicationId
        }
        if($InvalidPolicies.Count -eq 0)
        {
            Write-Host "There are no inactivity timeout settings configured for applications which are not defined in the desired state. This is expected. Proceeding."
        }
    }

    Write-Host "===================================================================================================="
    
    # Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        foreach($DesiredPolicyDefinition in $DesiredPolicyDefinitions)
        {
            $DesiredApplicationId = $DesiredPolicyDefinition.ApplicationId
            $DesiredWebSessionIdleTimeout = $DesiredPolicyDefinition.WebSessionIdleTimeout
            $DesiredPolicyHash = $DesiredApplicationId+"::"+$DesiredWebSessionIdleTimeout
            $DesiredPolicyHashes += $DesiredPolicyHash
            if($CurrentPolicyDefinitions.ApplicationId -NotContains $DesiredApplicationId)
            {
                $DriftSummary += Write-Output "CURRENT: $DesiredApplicationId does not have timeout set -> DESIRED: $DesiredApplicationId should have timeout of $DesiredWebSessionIdleTimeout"
            }
            elseif(($CurrentPolicyDefinitions.ApplicationId -Contains $DesiredApplicationId) -and ($CurrentPolicyHashes -NotContains $DesiredPolicyHash))
            {
                $MatchingWebSessionIdleTimeout = ($CurrentPolicyDefinitions | where {$_.ApplicationId -eq $DesiredApplicationId}).WebSessionIdleTimeout
                $DriftSummary += Write-Output "CURRENT: $DesiredApplicationId has timeout of $MatchingWebSessionIdleTimeout -> DESIRED: $DesiredApplicationId should have timeout of $DesiredWebSessionIdleTimeout"
            }
        }
        if($InvalidPolicies.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Inactivity policies are configured for apps which are not in the desired state -> DESIRED: Remove inactivity policies for these apps:"
            $DriftSummary += $InvalidPolicies | foreach { Write-Output `t$_ }
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
        Write-Host "------------------- Current State of Inactivity Timeout Settings After Changes ---------------------"
    }
    else {
        Write-Host "------------------- Current State of Inactivity Timeout Settings Before Changes --------------------"
        Write-Host "===================================================================================================="
    }
    if(!$CurrentPolicyDefinitions)
    {
        Write-Host "There are no inactivity timeout policies currently configured."
    }
    else
    {
        $ApplicationCounter = 0
        foreach($Entry in $CurrentPolicyDefinitions)
        {
            $ApplicationId = $Entry.ApplicationId
            $WebSessionIdleTimeout = $Entry.WebSessionIdleTimeout
            Write-Host "Application Timeout Policy[$ApplicationCounter]:"
            Write-Host "`tApplication ID:" $ApplicationId
            Write-Host "`tWeb Session Idle Timeout (hh:mm:ss):" $WebSessionIdleTimeout
            $ApplicationCounter += 1
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