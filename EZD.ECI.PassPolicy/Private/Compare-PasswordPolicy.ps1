function Compare-DomainPasswordPolicy {
    Param (
        [Parameter(Mandatory=$true)]
        [int]$DesiredPasswordValidityPeriodInDays
    )

    $DomainList = Get-MgDomain | Select-Object Id, PasswordValidityPeriodInDays
    $DriftCounter = 0
    $DriftSummary = @()

    Write-Host "Current: Drift Detection Run"

    foreach ($Domain in $DomainList) {
        $DomainId = $Domain.Id
        $CurrentPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays

        # Logging the meaning of the current and desired settings
        if ($CurrentPasswordValidityPeriodInDays -eq 0) {
            Write-Host "Domain $DomainId has a current password validity period of 0 day(s) 'Never Expires'."
        } else {
            Write-Host "Domain $DomainId has a current password validity period of $CurrentPasswordValidityPeriodInDays days."
        }

        if ($DesiredPasswordValidityPeriodInDays -eq 0) {
            Write-Host "Desired password validity period for domain $DomainId is set to 0 day(s) 'Never Expires'."
        } else {
            Write-Host "Desired password validity period for domain $DomainId is set to expire in $DesiredPasswordValidityPeriodInDays days."
        }

        if ($CurrentPasswordValidityPeriodInDays -ne $DesiredPasswordValidityPeriodInDays) {
            Write-Host "The current password validity period is $CurrentPasswordValidityPeriodInDays days."
            Write-Host "The password policy for domain $DomainId is not configured as desired."
            Write-Host "Its password expiration period should be set to $DesiredPasswordValidityPeriodInDays days."
            $DriftCounter++
            $DriftSummary += "Domain $($DomainId): CURRENT: $($CurrentPasswordValidityPeriodInDays) -> DESIRED: $($DesiredPasswordValidityPeriodInDays)"
        } else {
            Write-Host "Password policy for domain $DomainId is configured as desired. No change is necessary."
        }
    }

    Write-Host "DRIFT SUMMARY:"
    if ($DriftCounter -gt 0) {
        $DriftSummary | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "No drift detected. The current state aligns with the desired state for all domains."
    }

    Write-Host "===================================================================================================="
    Write-Host "------------------- Current State of Password Policies --------------------"
    Write-Host "===================================================================================================="
    foreach ($Domain in $DomainList) {
        Write-Host "Domain $($Domain.Id): Password Validity Period: $($Domain.PasswordValidityPeriodInDays) days"
    }
    Write-Host "===================================================================================================="

    if ($DriftCounter -gt 0) {
        Write-Host "DRIFT DETECTED: The current state does not align with the desired state for some domains."
    } else {
        Write-Host "NO DRIFT DETECTED: The current state aligns with the desired state for all domains."
    }
    Write-Host "===================================================================================================="

    return @{ "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
}