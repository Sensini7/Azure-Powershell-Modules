function Set-SignInText {
    param (
        [Parameter (Mandatory = $true)]
        [string] $TenantId,

        [Parameter (Mandatory = $true)]
        [string] $DesiredSignInText,

        [Parameter (Mandatory = $true)]
        [switch] $ExecuteChange
    )

    # Indicate whether this is a drift detection run or a deployment run
    if (-Not ($ExecuteChange)) {
        Write-Host "Current: Drift Detection Run"
    } else {
        Write-Host "Current: Deployment Run"
    }

    # Evaluate drift from the desired configuration
    $PreResults = Compare-SignInText
    $Iteration = $PreResults["Iteration"]
    $DriftCounter = $PreResults["DriftCounter"]
    $ReturnCode = $PreResults["ReturnCode"]
    $CurrentOrganizationBranding = $PreResults["CurrentOrganizationBranding"]
    $DriftSummary = $PreResults["DriftSummary"]
    
    if($ReturnCode -eq 1)
    {
        return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
    }

    # If this is a drift detection run, end the function
    if (-Not ($ExecuteChange)) 
    {
        Write-Host "This is a drift detection run. No changes will be made."
		if($DriftCounter -gt 0)
		{
			return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
		}
        else
		{
			return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
		}
    }
    else
    {
        # Execute the change if there is drift detected
        if($DriftCounter -gt 0)
        {
            Write-Host "-----------------------------------------------------------------------------------------------------"
            if(!$CurrentOrganizationBranding)
            {
                Write-Host "Now creating organizational branding object. This will also configure sign-in text."
                $HideOutput = New-MgOrganizationBrandingLocalization -OrganizationId $TenantId -SignInPageText $DesiredSignInText
            }
            else
            {
                Write-Host "Now setting sign-in text to desired state."
                $HideOutput = Update-MgOrganizationBranding -OrganizationId $TenantId -SignInPageText $DesiredSignInText
            }
            Write-Host "Now performing post-configuration checks sign-in text."
            Write-Host "-----------------------------------------------------------------------------------------------------"
    
            # Evaluate drift from the desired configuration
            $PostResults = Compare-SignInText
            $DriftCounter = $PostResults["DriftCounter"]
			$DriftSummary = $PostResults["DriftSummary"]

            if($DriftCounter -eq 0)
			{
				Write-Host "Settings are configured as desired. The change was successful."
				return Get-ReturnValue -ExitCode 3 -DriftSummary $DriftSummary
			}
			else
			{
				Write-Host "WARNING: Settings did not pass post-execution checks. The change was not successful."
				return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
			}
		}
		elseif ($DriftCounter -eq 0)
		{
			Write-Host "No change is required. Settings are already configured as desired."
			return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
		}
		else
		{
			Write-Host "WARNING: Unable to complete post-execution validation."
			return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
		}
	}
}