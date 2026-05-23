function Set-CrossTenantAccessSettingDefaults {
    param (
        [Parameter(Mandatory=$true)]
        [boolean] $BlockAll,

        [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
        [switch] $ExecuteChange = $false
	)

    # Indicate whether this is a drift detection run or a deployment run
	if (-Not ($ExecuteChange)) {
		Write-Host "Current: Drift Detection Run"
	} else {
		Write-Host "Current: Deployment Run"
	}

    ### Define desired state
    if ($BlockAll) {
        # Create the settings to block all access and reuse for each configuration item
        $BlockAllCrossTenantAccessPolicyB2BSetting = @{
            usersAndGroups = @{
                accessType = "blocked"
                targets = @(
                    @{
                        target = "AllUsers"
                        targetType = "user"
                    }
                )
            }
            applications = @{
                accessType = "blocked"
                targets = @(
                    @{
                        target = "AllApplications"
                        targetType = "application"
                    }
                )
            }
        }

        # Compile desired state params object
        $params = @{
            b2bCollaborationInbound = $BlockAllCrossTenantAccessPolicyB2BSetting
            b2bCollaborationOutbound = $BlockAllCrossTenantAccessPolicyB2BSetting
            b2bDirectConnectInbound = $BlockAllCrossTenantAccessPolicyB2BSetting
            b2bDirectConnectOutbound = $BlockAllCrossTenantAccessPolicyB2BSetting
            tenantRestrictions = $BlockAllCrossTenantAccessPolicyB2BSetting
            inboundTrust = @{
                isCompliantDeviceAccepted = $false
                isHybridAzureADJoinedDeviceAccepted = $false
                isMfaAccepted = $false
            }
        }
    } else {
        Write-Host "Only blocking all access is supported at this time."
    }

    # Evaluate drift from the desired configuration
	$PreResults = Compare-CrossTenantAccessSettingDefaults
	$Iteration = $PreResults["Iteration"]
	$DriftCounter = $PreResults["DriftCounter"]
	$DriftSummary = $PreResults["DriftSummary"]

   # If this is a drift detection run, end the function
    if (-Not ($ExecuteChange)) {
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
			Write-Host "Now updating default Entra B2B Organization Relationship settings with desired settings."
			$HideOutput = Update-MgPolicyCrossTenantAccessPolicyDefault -BodyParameter $params
			Write-Host "Now performing post-configuration checks for default Entra B2B Organization Relationship settings."
			Write-Host "-----------------------------------------------------------------------------------------------------"
			
			# Evaluate drift from the desired configuration
			$PostResults = Compare-CrossTenantAccessSettingDefaults
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