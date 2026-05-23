function Compare-SignInText {

    # Compile current state settings
    $CurrentOrganizationBranding = (Get-MgOrganizationBranding -OrganizationId $TenantId -ErrorAction SilentlyContinue)
    $CurrentSignInText = $CurrentOrganizationBranding.SignInPageText

    # Evaluate drift between the current and desired state
    $DriftCounter = 0
    if ($CurrentSignInText -ne $DesiredSignInText)
    {
        Write-Host "The sign-in text is not set to the desired state. It should be set to: [$DesiredSignInText]"
        $DriftCounter += 1
    }
	elseif ($CurrentSignInText -eq $DesiredSignInText) 
    {
		Write-Host "The sign-in text aligns with the desired state. No change is necessary."
	} else 
    {
		Write-Host "WARNING: The sign-in text could not be retrieved."
		$ReturnCode = 1
	}

    Write-Host "----------------------------------------------------------------------------------------------------"
    
    ### Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        if (!$CurrentSignInText)
        {
            $DriftSummary += Write-Output "CURRENT: No sign-in text is configured -> DESIRED: Sign-in text should be set to: [$DesiredSignInText]"
        }
        elseif ($CurrentSignInText -ne $DesiredSignInText)
        {
            $DriftSummary += Write-Output "CURRENT: Sign-in text is set to: [$CurrentSignInText] -> DESIRED: Sign-in text should be set to: [$DesiredSignInText]"
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
        Write-Host "--------------------------- Current State Sign-In Text After Changes -----------------------------"
    }
    else {
        Write-Host "--------------------------- Current State Sign-In Text Before Changes -----------------------------"
    }

    if(!$CurrentSignInText)
    {
        Write-Host "Custom sign-in text is not currently configured."
    }
    else
    {
        Write-Host "Current sign-in text: [$CurrentSignInText]"
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

    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "ReturnCode" = $ReturnCode; "CurrentOrganizationBranding" = $CurrentOrganizationBranding; "DriftSummary" = $DriftSummary }
}