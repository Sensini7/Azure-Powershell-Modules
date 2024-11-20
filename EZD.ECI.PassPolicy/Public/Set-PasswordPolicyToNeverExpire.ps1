function Set-DomainPasswordPolicy {
    # Determine desired settings from environment variables
    $PasswordValidityPeriodInDays = [int]$env:PASSWORD_EXPIRATION_PERIOD
    $ExecuteChange = [System.Convert]::ToBoolean($env:EXECUTE_CHANGE)

    # Convert 0 to a large number to represent "Never Expire"
    $NeverExpireValue = 2147483647
    if ($PasswordValidityPeriodInDays -eq 0) {
        $PasswordValidityPeriodInDays = $NeverExpireValue
    }
    
    Write-Host "===================================================================================================="

    $runType = if (-Not ($ExecuteChange)) { "DRIFT DETECTION RUN" } else { "DEPLOYMENT RUN" }
    Write-Host "CURRENT: $runType"

    $DomainList = Get-MgDomain | Select-Object Id, PasswordValidityPeriodInDays
    $DriftCounter = 0
    $DriftSummary = @()

    foreach ($Domain in $DomainList) {
        $DomainId = $Domain.Id
        $CurrentPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays

        # Logging the meaning of the current and desired settings

        
        Write-Host "===================================================================================================="

        if ($CurrentPasswordValidityPeriodInDays -eq $NeverExpireValue) {
            Write-Host "DOMAIN $DomainId has a current password validity period of $NeverExpireValue day(s) 'Never Expires'."
        } else {
            Write-Host "DOMAIN $DomainId has a current password validity period of $CurrentPasswordValidityPeriodInDays days."
        }
        
        Write-Host "===================================================================================================="

        if ($DesiredPasswordValidityPeriodInDays -eq $NeverExpireValue) {
            Write-Host "Desired password validity period for domain $DomainId is set to $NeverExpireValue day(s) 'Never Expires'."
        } else {
            Write-Host "Desired password validity period for domain $DomainId is set to expire in $PasswordValidityPeriodInDays days."
        }

        Write-Host "===================================================================================================="

        if ($CurrentPasswordValidityPeriodInDays -ne $PasswordValidityPeriodInDays) {
            $DriftCounter++
            $DriftSummary += "DOMAIN $($DomainId): CURRENT: $($CurrentPasswordValidityPeriodInDays) -> DESIRED: $($PasswordValidityPeriodInDays)"
            Write-Host "The password policy for domain $DomainId is not configured as desired."
            Write-Host "The current password validity period is $CurrentPasswordValidityPeriodInDays days. Its expiration period should be set to $PasswordValidityPeriodInDays days."
        } else {
            Write-Host "The Current Password policy for domain $DomainId is $PasswordValidityPeriodInDays days which matches the desired configuration. No change is necessary."
        }
        Write-Host "===================================================================================================="
    }

    if (-Not ($ExecuteChange)) {
        Write-Host "THIS IS A DRIFT DETECTION RUN. NO CHANGES WILL BE MADE"
        if ($DriftCounter -gt 0) {
            return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
        } else {
            return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
        }
    } else {
        if ($DriftCounter -gt 0) {
            Write-Host "===================================================================================================="
            Write-Host "UPDATING PASSWWORD POLICIES FOR ALL DOMAINS TO MATCH THE DESIRED STATE."
            Write-Host "===================================================================================================="

            foreach ($Domain in $DomainList) {
                $DomainId = $Domain.Id
                $CurrentPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays

                if ($CurrentPasswordValidityPeriodInDays -ne $PasswordValidityPeriodInDays) {
                    Write-Host "UPDATING DOMAIN: $DomainId"
                    Update-MgDomain -DomainId $DomainId -PasswordValidityPeriodInDays $PasswordValidityPeriodInDays
                }
            }
            Write-Host "===================================================================================================="
            Write-Host "NOW PERFORMING POST-CONFIGURATION CHECKS FOR PASSWORD POLICY SETTINGS."
            Write-Host "===================================================================================================="

            $PostDriftCounter = 0
            $PostDriftSummary = @()

            foreach ($Domain in Get-MgDomain | Select-Object Id, PasswordValidityPeriodInDays) {
                $DomainId = $Domain.Id
                $PostPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays

                if ($PostPasswordValidityPeriodInDays -ne $PasswordValidityPeriodInDays) {
                    $PostDriftCounter++
                    $PostDriftSummary += "DOMAIN $($DomainId): CURRENT: $($PostPasswordValidityPeriodInDays) -> DESIRED: $($PasswordValidityPeriodInDays)"
                }
            }

            if ($PostDriftCounter -eq 0) {
                Write-Host "SETTINGS ARE CONFIGURED AS DESIRED. THE CHANGE WAS SUCCESSFUL."
                return Get-ReturnValue -ExitCode 3 -DriftSummary $PostDriftSummary
            } else {
                Write-Host "WARNING: SETTINGS DID NOT PASS POST-EXECUTION CHECKS.THE CHANGE WAS NOT SUCCESSFUL"
                return Get-ReturnValue -ExitCode 1 -DriftSummary $PostDriftSummary
            }
        } elseif ($DriftCounter -eq 0) {
            Write-Host "NO CHANGE IS REQUIRED. SETTINGS ARE ALREADY CONFIGURED AS DESIRED"
            return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
        } else {
            Write-Host "WARNING: UNABLE TO COMPLETE POST-EXECUTION VALIDATION."
            return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
        }
    }
}