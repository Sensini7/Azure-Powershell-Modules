function Set-DomainPasswordPolicy {
    Param (
        [Parameter(Mandatory=$true, ParameterSetName='Expire')]
        [Parameter(Mandatory=$true, ParameterSetName='NeverExpire')]
        [ValidateSet("Expire", "NeverExpire")]
        [string]$PasswordPolicy,

        [Parameter(Mandatory=$true, ParameterSetName='Expire')]
        [int]$PasswordValidityPeriodInDays,

        [Parameter(ParameterSetName='Expire')]
        [Parameter(ParameterSetName='NeverExpire')]
        [switch]$ExecuteChange = $false
    )

    # Determine the desired password validity period
    if ($PasswordPolicy -eq "NeverExpire") {
        $DesiredPasswordValidityPeriodInDays = 2147483647  # A large number to represent "never expire"
    } else {
        $DesiredPasswordValidityPeriodInDays = $PasswordValidityPeriodInDays
    }

    # Indicate whether this is a drift detection run or a deployment run
    $runType = if (-Not ($ExecuteChange)) { "Drift Detection Run" } else { "Deployment Run" }
    Write-Host "Current: $runType"

    # Evaluate drift from the desired configuration using the helper function
    $DomainList = Get-MgDomain | Select-Object Id, PasswordValidityPeriodInDays
    $DriftCounter = 0
    $DriftSummary = @()

    foreach ($Domain in $DomainList) {
        $DomainId = $Domain.Id
        $CurrentPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays

        if ($CurrentPasswordValidityPeriodInDays -ne $DesiredPasswordValidityPeriodInDays) {
            $DriftCounter++
            $DriftSummary += "Domain $($DomainId): CURRENT: $($CurrentPasswordValidityPeriodInDays) -> DESIRED: $($DesiredPasswordValidityPeriodInDays)"
            Write-Host "The password policy for domain $DomainId is not configured as desired."
            Write-Host "The current password validity period is $CurrentPasswordValidityPeriodInDays days. It should be set to $DesiredPasswordValidityPeriodInDays days."
        } else {
            Write-Host "Password policy for domain $DomainId is configured as desired. No change is necessary."
        }
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
            Write-Host "Updating password policies for all domains to match the desired state."

            foreach ($Domain in $DomainList) {
                $DomainId = $Domain.Id
                $CurrentPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays

                if ($CurrentPasswordValidityPeriodInDays -ne $DesiredPasswordValidityPeriodInDays) {
                    Write-Host "Updating domain: $DomainId"
                    Update-MgDomain -DomainId $DomainId -PasswordValidityPeriodInDays $DesiredPasswordValidityPeriodInDays
                }
            }

            Write-Host "Now performing post-configuration checks for password policy settings."
            Write-Host "-----------------------------------------------------------------------------------------------------"

            # Re-evaluate drift from the desired configuration
            $PostDriftCounter = 0
            $PostDriftSummary = @()

            foreach ($Domain in Get-MgDomain | Select-Object Id, PasswordValidityPeriodInDays) {
                $DomainId = $Domain.Id
                $PostPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays

                if ($PostPasswordValidityPeriodInDays -ne $DesiredPasswordValidityPeriodInDays) {
                    $PostDriftCounter++
                    $PostDriftSummary += "Domain $($DomainId): CURRENT: $($PostPasswordValidityPeriodInDays) -> DESIRED: $($DesiredPasswordValidityPeriodInDays)"
                }
            }

            if ($PostDriftCounter -eq 0) {
                Write-Host "Settings are configured as desired. The change was successful."
                return Get-ReturnValue -ExitCode 3 -DriftSummary $PostDriftSummary
            } else {
                Write-Host "WARNING: Settings did not pass post-execution checks. The change was not successful."
                return Get-ReturnValue -ExitCode 1 -DriftSummary $PostDriftSummary
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