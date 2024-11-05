function Set-PasswordPolicy {

    Param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("None", "DisablePasswordExpiration")]
        [string]$PasswordPolicy,

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

    # Azure environment setup
    # Note: These IDs are placeholders and typically used for identifying specific applications
    if ($IsAzureGov) {
        $AzurePortalAppId = "c836cbdb-7a5b-44cc-a54f-564b4b486fc6"
    } else {
        $AzurePortalAppId = "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
    }

    ### Define desired state
    # Desired state for password policy based on the input parameter
    $DesiredPasswordPolicy = @{
        PasswordPolicies = $PasswordPolicy
    }

    # Evaluate drift from the desired configuration using the helper function
    $PreResults = Compare-PasswordPolicy -DesiredPolicy $DesiredPasswordPolicy.PasswordPolicies
    $DriftCounter = $PreResults["DriftCounter"]
    $DriftSummary = $PreResults["DriftSummary"]

    if ($PreResults["ReturnCode"] -eq 1) {
        return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
    }

    # If this is a drift detection run, end the function
    if (-Not ($ExecuteChange)) {
        Write-Host "This is a drift detection run. No changes will be made."
        if ($DriftCounter -gt 0) {
            return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
        } else {
            return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
        }
    } else {
        # Execute the change if there is drift detected
        if ($DriftCounter -gt 0) {
            Write-Host "-----------------------------------------------------------------------------------------------------"
            Write-Host "Updating password policies for all users to match the desired state."
            
            # Assuming a function or command exists to update password policy, such as Set-MgUserPasswordPolicy
            Get-MgUser -All | ForEach-Object {
                Update-MgUser -UserId $_.Id -PasswordPolicies $DesiredPasswordPolicy.PasswordPolicies
            }
            
            Write-Host "Now performing post-configuration checks for password policy settings."
            Write-Host "-----------------------------------------------------------------------------------------------------"

            # Re-evaluate drift from the desired configuration using the helper function again
            $PostResults = Compare-PasswordPolicy -DesiredPolicy $DesiredPasswordPolicy.PasswordPolicies
            $DriftCounter = $PostResults["DriftCounter"]
            $DriftSummary = $PostResults["DriftSummary"]

            if ($DriftCounter -eq 0) {
                Write-Host "Settings are configured as desired. The change was successful."
                return Get-ReturnValue -ExitCode 3 -DriftSummary $DriftSummary
            } else {
                Write-Host "WARNING: Settings did not pass post-execution checks. The change was not successful."
                return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
            }
        } elseif ($DriftCounter -eq 0) {
            Write-Host "No change is required. Settings are already configured as desired."
            return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
        } else {
            Write-Host "WARNING: Unable to complete post-execution validation."
            return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
        }
    }
}