function Compare-PasswordPolicy {

    Param (
        [Parameter(Mandatory=$true)]
        [string]$DesiredPolicy
    )

    # Compile the current state of the password policies
    $CurrentPolicies = Get-MgUser -All | Select-Object -ExpandProperty PasswordPolicies -Unique

    # Generate a list of current policy settings
    $CurrentPolicyHashes = @()
    foreach ($CurrentPolicy in $CurrentPolicies) {
        $CurrentPolicyHashes += $CurrentPolicy
    }

    # Calculate drift of the current state from the desired state
    $DriftCounter = 0

    # Check if there are any missing or misconfigured password policies
    if ($CurrentPolicyHashes -NotContains $DesiredPolicy) {
        Write-Host "The password policy is not configured as desired."
        Write-Host "The password policy should be set to $DesiredPolicy."
        $DriftCounter += 1
    } else {
        Write-Host "Password policy is configured as desired. No change is necessary."
    }

    # Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if ($DriftCounter -gt 0) {
        $DriftSummary += Write-Output "CURRENT: Password policy is not set to $DesiredPolicy -> DESIRED: Password policy should be $DesiredPolicy"
    } else {
        $DriftSummary += Write-Output "No drift detected. The current state aligns with the desired state."
    }

    $DriftSummary | foreach { Write-Host $_ }

    Write-Host "===================================================================================================="

    # Summarize current state
    Write-Host "------------------- Current State of Password Policies --------------------"
    Write-Host "===================================================================================================="
    if (!$CurrentPolicies) {
        Write-Host "There are no password policies currently configured."
    } else {
        $PolicyCounter = 0
        foreach ($Policy in $CurrentPolicies) {
            Write-Host "Password Policy[$PolicyCounter]:"
            Write-Host "`tPolicy: $Policy"
            $PolicyCounter += 1
        }
    }

    Write-Host "===================================================================================================="
    if ($DriftCounter -gt 0) {
        Write-Host "DRIFT DETECTED: The current state does not align with the desired state."
    } else {
        Write-Host "NO DRIFT DETECTED: The current state aligns with the desired state."
    }
    Write-Host "===================================================================================================="

    return @{ "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
}