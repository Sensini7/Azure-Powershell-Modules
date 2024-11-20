function Compare-DomainPasswordPolicy {
    Param (
        [Parameter(Mandatory=$true)]
        [int]$DesiredPasswordValidityPeriodInDays
    )

    # Convert 0 to a large number to represent "Never Expire"
    $NeverExpireValue = 2147483647
    if ($DesiredPasswordValidityPeriodInDays -eq 0) {
        $DesiredPasswordValidityPeriodInDays = $NeverExpireValue
    }
    
    $DomainList = Get-MgDomain | Select-Object Id, PasswordValidityPeriodInDays
    $DriftCounter = 0
    $DriftSummary = @()

    
    Write-Host "===================================================================================================="

    Write-Host "CURRENT: DRIFT DETECTION RUN"

     
    Write-Host "===================================================================================================="

    foreach ($Domain in $DomainList) {
        $DomainId = $Domain.Id
        $CurrentPasswordValidityPeriodInDays = $Domain.PasswordValidityPeriodInDays

        # Logging the meaning of the current and desired settings

        
        Write-Host "===================================================================================================="

        if ($CurrentPasswordValidityPeriodInDays -eq $NeverExpireValue) {
            Write-Host "Domain $DomainId has a current password validity period of $NeverExpireValue day(s) 'Never Expires'."
        } else {
            Write-Host "Domain $DomainId has a current password validity period of $CurrentPasswordValidityPeriodInDays days. It Expires In $CurrentPasswordValidityPeriodInDays "
        }
        
        
        Write-Host "===================================================================================================="

        if ($DesiredPasswordValidityPeriodInDays -eq $NeverExpireValue) {
            Write-Host "Desired password validity period for domain $DomainId is set to $NeverExpireValue day(s) 'Never Expires'."
        } else {
            Write-Host "Desired password validity period for domain $DomainId is set to expire in $DesiredPasswordValidityPeriodInDays days."
        }
        
        Write-Host "===================================================================================================="

        if ($CurrentPasswordValidityPeriodInDays -ne $DesiredPasswordValidityPeriodInDays) {
            Write-Host "The current password validity period is $CurrentPasswordValidityPeriodInDays days."
            Write-Host "The password policy for domain $DomainId is not configured as desired."
            Write-Host "Its password expiration period should be set to $DesiredPasswordValidityPeriodInDays days."
            $DriftCounter++
            $DriftSummary += "DOMAIN $($DomainId): CURRENT: $($CurrentPasswordValidityPeriodInDays) -> DESIRED: $($DesiredPasswordValidityPeriodInDays)"
        } else {
            Write-Host "Password policy for domain $DomainId is configured as desired. No change is necessary."
        }
    }

    
    Write-Host "===================================================================================================="

    Write-Host "DRIFT SUMMARY:"
    if ($DriftCounter -gt 0) {
        $DriftSummary | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "No drift detected. The current state aligns with the desired state for all domains."
    }

    Write-Host "===================================================================================================="
    Write-Host "------------------- CURRENT STATE OF PASSWORD POLICIES --------------------"
    Write-Host "===================================================================================================="

    foreach ($Domain in $DomainList) {
        Write-Host "DOMAIN $($Domain.Id): Password Validity Period: $($Domain.PasswordValidityPeriodInDays) days"
    }
    Write-Host "===================================================================================================="

    if ($DriftCounter -gt 0) {
        Write-Host "DRIFT DETECTED: THE CURRENT STATE DOES NOT ALIGN WITH THE DESIRED STATE FOR SOME DOMAINS"
    } else {
        Write-Host "NO DRIFT DETECTED: THE CURRENT STATE DOES NOT ALIGN WITH THE DESIRED STATE FOR ALL DOMAINS"
    }
    Write-Host "===================================================================================================="

    return @{ "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
}