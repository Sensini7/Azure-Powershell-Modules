function Set-EnterpriseAppUserConsentSetting {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("DoNotAllow", "AllowFromVerifiedPublishers", "AllowAll")]
        [string] $DesiredConsentSetting,

        [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
        [switch] $ExecuteChange = $false
    )

    # Indicate whether this is a drift detection run or a deployment run
    if (-Not ($ExecuteChange)) {
        Write-Host "Current: Drift Detection Run"
    } else {
        Write-Host "Current: Deployment Run"
    }

    ## Compile desired settings 
    # DoNotAllow is empty string as the lack of `ManagePermissionGrantsForSelf` tells Entra to disallow user consent 
    $MappedSettings = @{
        AllowFromVerifiedPublishers = "ManagePermissionGrantsForSelf.microsoft-user-default-low"
        AllowAll = "ManagePermissionGrantsForSelf.microsoft-user-default-legacy"
        DoNotAllow = ""
    }

    # Evaluate drift from the desired configuration
    Write-Host "Now evaluating drift between current and desired state."
    $PreResults = Compare-EnterpriseAppUserConsentSetting
	$Iteration = $PreResults["Iteration"]
	$DriftCounter = $PreResults["DriftCounter"]
	$ReturnCode = $PreResults["ReturnCode"]
	$DriftSummary = $PreResults["DriftSummary"]
    $CurrentlyEnabledSetting = $PreResults["CurrentlyEnabledSetting"]
    $CurrentUserConsentSettings = $PreResults["CurrentUserConsentSettings"]

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
            Write-Host "Updating Default User Consent Settings from $CurrentlyEnabledSetting to $DesiredConsentSetting"

            ## The logic in this switch will get the current setting so that we may ensure its removal from the bodyparameter value
            switch ($CurrentlyEnabledSetting) {
                ## Instead of creating a block for each case, we use an expression to catch all cases except the special one
                ## The value of $_ is the key of the current case
                {$_ -ne "DoNotAllow"} {
                    $Body = @{
                        DefaultUserRolePermissions = @{
                            permissionGrantPoliciesAssigned = $CurrentUserConsentSettings -NotMatch $MappedSettings[$_]
                        }
                    }
                }
                ## DoNotAllow is configured by not having the AllowAll/AllowFromVerifiedPublishers values in the bodyparameter
                Default {
                    $Body = @{
                        DefaultUserRolePermissions = @{
                            permissionGrantPoliciesAssigned = $CurrentUserConsentSettings
                        }
                    }
                }
            }
            if ($DesiredConsentSetting -ne "DoNotAllow") {
                $Body.DefaultUserRolePermissions.permissionGrantPoliciesAssigned += $MappedSettings[$DesiredConsentSetting]
            }
            $HideOutput = Update-MgPolicyAuthorizationPolicy -BodyParameter $Body
            Write-Host "Now performing post-configuration checks for Enterprise App Consent Settings."
            Write-Host "-----------------------------------------------------------------------------------------------------"

            # Evaluate drift from the desired configuration
            $PostResults = Compare-EnterpriseAppUserConsentSetting
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