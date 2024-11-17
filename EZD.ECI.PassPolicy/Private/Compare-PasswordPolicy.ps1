function Compare-DomainPasswordPolicy {
    Param (
        [Parameter(Mandatory=$true)]
        [int]$DesiredPasswordValidityPeriodInDays
    )

    # Retrieve the current state of the password validity period for each domain
    $DomainList = Get-MgDomain | Select-Object Id, PasswordValidityPeriodInDays

    # Initialize drift counter and summary
    $DriftCounter = 0
    $DriftSummary = @()

    # Output the current run type
    Write-Host "Current: Drift Detection Run"

    # Iterate over each domain to check for drift
    foreach ($Domain in $DomainList) {
        $DomainId = $Domain.Id
        $CurrentPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays
        
        # Check if the current setting matches the desired setting
        if ($CurrentPasswordValidityPeriodInDays -ne $DesiredPasswordValidityPeriodInDays) {
            Write-Host "The password policy for domain $DomainId is not configured as desired."
            Write-Host "The current password validity period is $CurrentPasswordValidityPeriodInDays days."
            Write-Host "It should be set to $DesiredPasswordValidityPeriodInDays days."
            $DriftCounter++
            $DriftSummary += "Domain $($DomainId): CURRENT: $($CurrentPasswordValidityPeriodInDays) -> DESIRED: $($DesiredPasswordValidityPeriodInDays)"
        } else {
            Write-Host "Password policy for domain $DomainId is configured as desired. No change is necessary."
        }
    }

    # Output drift summary
    Write-Host "DRIFT SUMMARY:"
    if ($DriftCounter -gt 0) {
        $DriftSummary | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "No drift detected. The current state aligns with the desired state for all domains."
    }

    Write-Host "===================================================================================================="

    # Summarize current state
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