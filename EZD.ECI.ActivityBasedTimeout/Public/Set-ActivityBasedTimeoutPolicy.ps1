function Set-ActivityBasedTimeoutPolicy {

	Param (
        [Parameter(Mandatory=$false)]
		$WebSessionidleTimeout,

        [Parameter(Mandatory=$false)]
		$IsAzureGov,

        [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
        [switch] $ExecuteChange = $false
	)

	# Indicate whether this is a drift detection run or a deployment run
	if (-Not ($ExecuteChange)) {
		Write-Host "Current: Drift Detection Run"
	} else {
		Write-Host "Current: Deployment Run"
	}

	if ($IsAzureGov = $true) {
		$AzurePortalAppId = "c836cbdb-7a5b-44cc-a54f-564b4b486fc6"
	} else {
		$AzurePortalAppId = "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
	}

	### Define desired state
	# Compile desired state timeout definition component of the params object
	$IdleTimeoutDefinition = @{
		ActivityBasedTimeoutPolicy = @{
			Version = 1
			ApplicationPolicies = @(
				## Uncomment the following block to set the WebSessionIdleTimeout value for M365 default
				# @{
				# 	ApplicationId = "default"
				# 	WebSessionIdleTimeout = $WebSessionidleTimeout
				# },
				## The following Application ID specified is for the Azure Portal Enterprise App.
				@{
					ApplicationId = $AzurePortalAppId
					WebSessionIdleTimeout = $WebSessionidleTimeout
				}
			)
		}
	} | ConvertTo-Json -Depth 3

	# Compile desired state params object
	$params = @{
		definition = @(
			$IdleTimeoutDefinition
		)
		displayName = "ActivityBasedTimeoutPolicy"
		isOrganizationDefault = $true
	}

	# Compile desired settings for drift evaluation
	$DesiredPolicyDefinitions = ($params.definition | ConvertFrom-Json).ActivityBasedTimeoutPolicy.ApplicationPolicies

	# Evaluate drift from the desired configuration
	$ActivityBasedTimeoutPolicy = Get-MgPolicyActivityBasedTimeoutPolicy | Where {$_.displayName -eq "ActivityBasedTimeoutPolicy"}
	$PreResults = Compare-ActivityBasedTimeoutPolicy
	$Iteration = $PreResults["Iteration"]
	$DriftCounter = $PreResults["DriftCounter"]
	$ReturnCode = $PreResults["ReturnCode"]
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
		if ($DriftCounter -gt 0)
		{
			Write-Host "-----------------------------------------------------------------------------------------------------"
			if (-Not ($ActivityBasedTimeoutPolicy)) {
				Write-Host "Now creating new Azure inactivity timeout policy with desired settings."
				$HideOutput = New-MgPolicyActivityBasedTimeoutPolicy -BodyParameter $params
			} else {
				Write-Host "Now updating Azure inactivity timeout settings with desired settings."
				$HideOutput = Update-MgPolicyActivityBasedTimeoutPolicy -ActivityBasedTimeoutPolicyId $ActivityBasedTimeoutPolicy.id -BodyParameter $params
			}
			Write-Host "Now performing post-configuration checks for Azure inactivity timeout settings."
			Write-Host "-----------------------------------------------------------------------------------------------------"

			# Evaluate drift from the desired configuration
			$ActivityBasedTimeoutPolicy = $null
			$ActivityBasedTimeoutPolicy = Get-MgPolicyActivityBasedTimeoutPolicy | Where {$_.displayName -eq "ActivityBasedTimeoutPolicy"}
			$PostResults = Compare-ActivityBasedTimeoutPolicy
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