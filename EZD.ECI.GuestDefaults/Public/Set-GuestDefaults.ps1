function Set-GuestDefaults {

    param (
        [Parameter (Mandatory = $true)]
        [string] $GuestUserRoleIdGuid,

        [Parameter (Mandatory = $true)]
        [string] $AllowInvitesFrom,

        [Parameter(Mandatory = $true)]
        [switch] $AllowSelfServiceSignup,

        [Parameter(Mandatory = $true)]
        [switch] $AllowExternalIdentitiesToLeave,

        [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
        [switch] $ExecuteChange 
    )

    # Indicate whether this is a drift detection run or a deployment run
    if (-Not ($ExecuteChange)) {
        Write-Host "Current: Drift Detection Run"
    } else {
        Write-Host "Current: Deployment Run"
    }

    # GuestUserRoleIdGuid:
    #   a0b1b346-4d3e-4e8b-98f8-753987be4970 = Guests have the same access to Microsoft Entra resources as member users
    #   10dae51f-b6af-4016-8d66-8c2a99b929b3 = Guests can see membership of all non-hidden groups
    #   2af84b1e-32c8-42b7-82bc-daa82404023b = Guests can't see membership of any groups

    # AllowInvitesFrom:
    #   everyone = All users can invite guest users, including other guest users
    #   adminsGuestInvitersAndAllMembers = All users except guest users can invite guest users
    #   adminsAndGuestInviters = Only guest inviter and higher roles can invite guest users
    #   none = No one can invite guest users

    ## Compile desired state parameters
    # Parameters for Guest user access and invite restrictions
    $AuthPolicyParams = @{
        BodyParameter = @{
            guestUserRoleId = $GuestUserRoleIdGuid
            allowInvitesFrom = $AllowInvitesFrom
        }
    }

    # Parameter for Enable guest self-service sign up via user flows
    $AuthFlowPolicyParams = @{
        BodyParameter = @{
            selfServiceSignUp = @{
                isEnabled = $false
            }
        }
    }

    # Parameter for External user leave settings
    $ExternalLeaveParams = @{
        BodyParameter = @{
            allowExternalIdentitiesToLeave = $true
        }
    }

    # Sets the following configurations:
    #
    # Guest user access restrictions: Guest user access is restricted to properties and memberships of their own directory objects (most restrictive)
    # Guest invite restrictions: Only users assigned to specific admin roles can invite guest users
    # Enable guest self-service sign up via user flows: No
    # Allow external users to remove themselves from your organization: Yes

     # Evaluate drift from the desired configuration
    Write-Host "Now evaluating drift between current and desired state."
    $PreResults = Compare-GuestDefaults
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
        if($DriftCounter -gt 0)
        {
            # Execute the change
            Write-Host "-----------------------------------------------------------------------------------------------------"
            Write-Host "Now deploying desired Entra ID external collaboration settings configuration."
            $HideOutput = Update-MgPolicyAuthorizationPolicy @AuthPolicyParams
            $HideOutput = Update-MgBetaPolicyAuthenticationFlowPolicy @AuthFlowPolicyParams
            $HideOutput = Update-MgBetaPolicyExternalIdentityPolicy @ExternalLeaveParams
            Write-Host "Now performing post-configuration checks for Entra ID external collaboration settings."
            Write-Host "-----------------------------------------------------------------------------------------------------"
            
            # Validate alignment with desired state
            $PostResults = Compare-GuestDefaults
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