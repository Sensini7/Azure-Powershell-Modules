function Set-DomainPasswordPolicy {
    param (
        [int]$PasswordValidityPeriodInDays,
        [bool]$ExecuteChange
    )

    # Convert 0 to a large number to represent "Never Expire"
    $NeverExpireValue = 2147483647
    if ($PasswordValidityPeriodInDays -eq 0) {
        $PasswordValidityPeriodInDays = $NeverExpireValue
    }

    Write-Host "===================================================================================================="
    $runType = if (-Not ($ExecuteChange)) { "DRIFT DETECTION RUN" } else { "DEPLOYMENT RUN" }
    Write-Host "CURRENT: $runType"
    Write-Host "===================================================================================================="

    # Call the helper function for drift detection
    $DriftResult = Compare-DomainPasswordPolicy -DesiredPasswordValidityPeriodInDays $PasswordValidityPeriodInDays
    $DriftCounter = $DriftResult["DriftCounter"]
    $DriftSummary = $DriftResult["DriftSummary"]

    if (-Not ($ExecuteChange)) {
        Write-Host "THIS IS A DRIFT DETECTION RUN. NO CHANGES WILL BE MADE"
        if ($DriftCounter -gt 0) {
            Write-Host "Drift detected for the following domains:"
            $DriftSummary | ForEach-Object { Write-Host $_ }
            return @{ "ExitCode" = 2; "DriftSummary" = $DriftSummary }
        } else {
            Write-Host "No drift detected. All password policies are configured as desired."
            return @{ "ExitCode" = 0; "DriftSummary" = $DriftSummary }
        }
    } else {
        if ($DriftCounter -gt 0) {
            Write-Host "UPDATING PASSWORD POLICIES FOR ALL DOMAINS TO MATCH THE DESIRED STATE."
            foreach ($Domain in $DriftSummary) {
                $DomainId = ($Domain -split ':')[1].Trim().Split(' ')[0]
                Write-Host "UPDATING DOMAIN: $DomainId"
                Update-MgDomain -DomainId $DomainId -PasswordValidityPeriodInDays $PasswordValidityPeriodInDays
            }

            Write-Host "===================================================================================================="
            Write-Host "PERFORMING POST-CONFIGURATION CHECKS."
            Write-Host "===================================================================================================="

            # Perform a post-configuration drift detection
            $PostDriftResult = Compare-DomainPasswordPolicy -DesiredPasswordValidityPeriodInDays $PasswordValidityPeriodInDays
            if ($PostDriftResult["DriftCounter"] -eq 0) {
                Write-Host "SETTINGS ARE CONFIGURED AS DESIRED. THE CHANGE WAS SUCCESSFUL."
                return @{ "ExitCode" = 3; "DriftSummary" = $PostDriftResult["DriftSummary"] }
            } else {
                Write-Host "WARNING: SETTINGS DID NOT PASS POST-EXECUTION CHECKS."
                return @{ "ExitCode" = 1; "DriftSummary" = $PostDriftResult["DriftSummary"] }
            }
        } else {
            Write-Host "NO CHANGE IS REQUIRED. SETTINGS ARE ALREADY CONFIGURED AS DESIRED."
            return @{ "ExitCode" = 0; "DriftSummary" = $DriftSummary }
        }
    }
}