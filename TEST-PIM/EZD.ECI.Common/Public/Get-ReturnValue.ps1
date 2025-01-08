function Get-ReturnValue {
    Param (
        [Parameter(Mandatory=$true)]
        $ExitCode,
        [Parameter(Mandatory=$false)]
        $DriftSummary
    )

    switch($ExitCode) {
        0 { $ReturnValue = @{ "ExitCode" = 0; "ExitLogs" = "No drift detected." } }
        1 { $ReturnValue = @{ "ExitCode" = 1; "ExitLogs" = "WARNING: An execution error occurred." } }
        2 { $ReturnValue = @{ "ExitCode" = 2; "ExitLogs" = $DriftSummary } }
        3 { $ReturnValue = @{ "ExitCode" = 3; "ExitLogs" = "Change was successful." } }
        Default {
            Write-Host "WARNING: An invalid exit code was provided."
            $ReturnValue = @{ "ExitCode" = 1; "ExitLogs" = "WARNING: An execution error occurred." }
        }
    }

    return $ReturnValue
}


foreach ($Domain in $DriftSummary) {
    # Validate the structure of the DriftSummary entry
    if ($Domain -match '^DOMAIN\s+([^\s:]+):') {
        # Extract the domain ID using regex
        $DomainId = $matches[1]
        Write-Host "UPDATING DOMAIN: $DomainId"

        try {
            # Update the domain with the desired password validity period
            Update-MgDomain -DomainId $DomainId -PasswordValidityPeriodInDays $PasswordValidityPeriodInDays
        } catch {
            Write-Host "Error updating domain ($DomainId): $_"
        }
    } else {
        Write-Host "Invalid DriftSummary format: $Domain"
    }
}
