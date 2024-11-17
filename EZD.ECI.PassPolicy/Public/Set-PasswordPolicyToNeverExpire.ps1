function Set-DomainPasswordPolicy {
    # Determine desired settings from environment variables
    $PasswordValidityPeriodInDays = [int]$env:PASSWORD_EXPIRATION_PERIOD
    $ExecuteChange = [bool]$env:EXECUTE_CHANGE

    # Determine the desired password policy
    $PasswordPolicy = if ($PasswordValidityPeriodInDays -eq 0) { "NeverExpire" } else { "Expire" }

    if ($PasswordPolicy -eq "NeverExpire") {
        $DesiredPasswordValidityPeriodInDays = 0
    } else {
        $DesiredPasswordValidityPeriodInDays = $PasswordValidityPeriodInDays
    }

    $runType = if (-Not ($ExecuteChange)) { "Drift Detection Run" } else { "Deployment Run" }
    Write-Host "Current: $runType"

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
            
            # Enhanced logging for current password validity period
            if ($CurrentPasswordValidityPeriodInDays -eq 0) {
                Write-Host "The current password validity period is 0 days, meaning it never expires."
            } else {
                Write-Host "The current password validity period is $CurrentPasswordValidityPeriodInDays days, meaning it expires in $CurrentPasswordValidityPeriodInDays days."
            }

            # Enhanced logging for desired password validity period
            if ($DesiredPasswordValidityPeriodInDays -eq 0) {
                Write-Host "It should be set to 0 days, meaning it should never expire."
            } else {
                Write-Host "It should be set to $DesiredPasswordValidityPeriodInDays days, meaning it should expire in $DesiredPasswordValidityPeriodInDays days."
            }
        } else {
            if ($DesiredPasswordValidityPeriodInDays -eq 0) {
                Write-Host "The current password policy for domain $DomainId is set to never expire, which matches the desired configuration. No change is necessary."
            } else {
                Write-Host "The current password policy for domain $DomainId is set to expire in $DesiredPasswordValidityPeriodInDays days, which matches the desired configuration. No change is necessary."
            }
        }
    }

    if (-Not ($ExecuteChange)) {
        Write-Host "This is a drift detection run. No changes will be made."
        if ($DriftCounter -gt 0) {
            return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
        } else {
            return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
        }
    } else {
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