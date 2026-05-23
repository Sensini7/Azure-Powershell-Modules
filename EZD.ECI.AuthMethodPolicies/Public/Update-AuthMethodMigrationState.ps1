function Update-AuthMethodMigrationState {

    param (
        [Parameter (Mandatory = $true)]
        [ValidateSet ("preMigration","migrationInProgress", "migrationComplete")]
        [string] $PolicyMigrationState,

        [switch] $ExecuteChange 
    )

    $ReturnVariable = 0

    # Evaluate drift from the desired configuration
    Write-Host "Now evaluating drift between current and desired state."
    $PreResults = Compare-AuthMethodMigrationState
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
        if($DriftCounter -gt 0)
        {
            Write-Host "-----------------------------------------------------------------------------------------------------"
            Write-Host "Now configuring Authentication Method Policy migration state to $PolicyMigrationState"
            Update-MgPolicyAuthenticationMethodPolicy -PolicyMigrationState $PolicyMigrationState
            Write-Host "Now performing post-configuration checks for Authentication Method Policy migration."
            Write-Host "-----------------------------------------------------------------------------------------------------"

            # Evaluate drift from the desired configuration
            $PostResults = Compare-AuthMethodMigrationState
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