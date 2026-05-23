function Compare-AuthMethodMigrationState {

    # Compile t he current state
    $DriftCounter = 0
    $CurrentState = (Get-MgPolicyAuthenticationMethodPolicy).PolicyMigrationState

    # Evaluate drift from the desired state
    if ($CurrentState -ne $PolicyMigrationState)
    {
		Write-Host "The authentication method migration state does not align with the desired state. It should be set to: '$PolicyMigrationState'"
        $DriftCounter += 1
	}
	elseif ($CurrentState -eq $PolicyMigrationState) 
    {
		Write-Host "The authentication method migration state aligns with the desired state ($PolicyMigrationState). No change is necessary."
	} else 
    {
		Write-Host "WARNING: The authentication method migration state could not be retrieved."
        $DriftCounter += 1
	}
    Write-Host "===================================================================================================="

    # Summarize drift
    $DriftSummary += @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        if ($CurrentState -ne $PolicyMigrationState)
        {
            $DriftSummary += Write-Output "CURRENT: Authentication method policy migration state is $CurrentState -> DESIRED: Setting value should be $PolicyMigrationState"
        }
    }
    else
    {
        $DriftSummary += Write-Output "No drift detected. The current state aligns with the desired state." 
    }

    Write-Host "===================================================================================================="
  
    # Summarize current state
    if($Iteration -gt 0) {
        Write-Host "------------- Current State of Authentication Method Migration State After Changes ---------------"
    }
    else {
        Write-Host "------------- Current State of Authentication Method Migration State Before Changes --------------"
    }
    
    Write-Host "Current state of authentication method migration state: $CurrentState"

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

    $Iteration += 1
    
    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }

}