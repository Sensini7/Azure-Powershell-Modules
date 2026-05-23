function Compare-EntraCertificateAuthorities {

    # Reset key variables prior to execution
    $CloudCertificateAuthorities = $null

    # Generate a list of current root and intermediate certificate thumbprints
    Write-Host "Now gathering current Entra ID certificate authority settings."
    $CloudCertificateSummary = @()
    $CloudCertificateAuthorities = (Get-MgOrganizationCertificateBasedAuthConfiguration -OrganizationId $TenantId).CertificateAuthorities
    ForEach($CloudCertificateAuthority in $CloudCertificateAuthorities)
    {
        $CloudCertificate = $CloudCertificateAuthority.Certificate
        $CloudCertificateX509 = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CloudCertificate)
        $CloudCertificateThumbprint = $CloudCertificateX509.Thumbprint
        if($CloudCertificateAuthority.IsRootAuthority -eq $True)
        {
            $CloudAuthorityTypeLabel = "Root"
        }
        else
        {
            $CloudAuthorityTypeLabel = "Intermediate"
        }
        $CloudCertificateRevocationListUrl = $CloudCertificateAuthority.CertificateRevocationListUrl
        $CloudCertificateDetails = @{
            "CloudCertificateThumbprint" = $CloudCertificateThumbprint
            "CloudAuthorityTypeLabel" = $CloudAuthorityTypeLabel
            "CloudCertificateRevocationListUrl" = $CloudCertificateRevocationListUrl
            "CloudAuthorityHash" = $CloudCertificateThumbprint+":"+$CloudAuthorityTypeLabel
            "CloudCrlHash" = $CloudCertificateThumbprint+":"+$CloudCertificateRevocationListUrl
        }
        $CloudCertificateSummary += $CloudCertificateDetails
    }

    # Evaluate whether each certificate authority is already configured in Entra ID
    Write-Host "Now evaluating whether any changes to certificate authority configuration are necessary in the environment."
    $CertificatesToAdd = @()
    $CertificatesToRemove = @()
    $CertificatesToModify = @()
    $CertificatesToAddOrModify = @()
    $DriftCounter = 0
    foreach($CloudCertificate in $CloudCertificateSummary)
    {
        $CloudCertificateThumbprint = $CloudCertificate.CloudCertificateThumbprint
        if($CertificateSummary.CertificateThumbprint -NotContains $CloudCertificateThumbprint)
        {
            Write-Host "Certificate authority with thumbprint $CloudCertificateThumbprint is configured in the tenant but is not in the desired state. It should be removed."
            $CertificatesToRemove += $CloudCertificateThumbprint
            $DriftCounter += 1
        }
    }
    if($CertificatesToRemove.Count -eq 0)
    {
        Write-Host "There are no certificate authorities configured in the tenant which are not included in the desired CA list. No CAs should be removed."
    }
    
    foreach($Certificate in $CertificateSummary)
    {
        $CertificateName = $Certificate.CertificateName
        $CertificateThumbprint = $Certificate.CertificateThumbprint
        $AuthorityTypeLabel = $Certificate.AuthorityTypeLabel
        $CertificateRevocationListUrl = $Certificate.CertificateRevocationListUrl
        $AuthorityHash = $Certificate.AuthorityHash
        $CrlHash = $Certificate.CrlHash
        Write-Host "----------------------------------------------------------------------------------------------------"
        Write-Host "Now evaluating configuration of certificate $CertificateName."
        if($CloudCertificateSummary.CloudCertificateThumbprint -Contains $CertificateThumbprint)
        {
            if(($CloudCertificateSummary.CloudAuthorityHash -Contains $AuthorityHash) -and ($CloudCertificateSummary.CloudCrlHash -Contains $CrlHash))
            {
                Write-Host "$AuthorityTypeLabel certificate authority $CertificateName is already configured as expected. No change is necessary to this certificate authority."
            }
            else
            {
                if(($CloudCertificateSummary.CloudAuthorityHash -NotContains $AuthorityHash) -and ($CloudCertificateSummary.CloudCrlHash -NotContains $CrlHash))
                {
                    Write-Host "Certificate authority $CertificateName is present in tenant, but both its certificate authority type and certificate revocation list are misconfigured."
                    Write-Host "Certificate authority $CertificateName should be configured with certificate authority type $AuthorityTypeLabel and certificate revocation list $CertificateRevocationListUrl."
                    $CertificatesToModify += $CertificateName
                    $DriftCounter += 1
                }
                elseif($CloudCertificateSummary.CloudAuthorityHash -NotContains $AuthorityHash)
                {
                    Write-Host "Certificate authority $CertificateName is present in tenant, but its certificate authority type is misconfigured."
                    Write-Host "Certificate authority $CertificateName should be configured with certificate authority type $AuthorityTypeLabel."
                    $CertificatesToModify += $CertificateName
                    $DriftCounter += 1
                }
                elseif($CloudCertificateSummary.CloudCrlHash -NotContains $CrlHash)
                {
                    Write-Host "$AuthorityTypeLabel certificate authority $CertificateName is present in tenant, but its certificate revocation list is misconfigured."
                    Write-Host "$AuthorityTypeLabel certificate authority $CertificateName should be configured with certificate revocation list $CertificateRevocationListUrl."
                    $CertificatesToModify += $CertificateName
                    $DriftCounter += 1
                }
                else
                {
                    Write-Host "ERROR: Failed to evaluate if $CertificateName is properly configured."
                    $CertificatesToAdd += $CertificateName
                    $DriftCounter += 1
                    return 1
                }
            }
        }
        else
        {
            Write-Host "$CertificateName is not present in tenant."
            Write-Host "$AuthorityTypeLabel certificate authority $CertificateName should be configured with certificate revocation list $CertificateRevocationListUrl."
            $CertificatesToAdd += $CertificateName
            $DriftCounter += 1
        }
    }
    $CertificatesToAddOrModify = $CertificatesToAdd + $CertificatesToModify

    Write-Host "===================================================================================================="

    # Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        if($CertificatesToAdd.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Certificate authorities are included in the desired state which are missing from the tenant -> DESIRED: These CAs should be added:"
            $CertificatesToAdd | foreach { $DriftSummary += Write-Output `t$_ }
        }
        if($CertificatesToModify.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Certificate authorities are included in the desired state which are improperly configured in the tenant -> DESIRED: These CAs should be modified:"
            $CertificatesToModify | foreach { $DriftSummary += Write-Output `t$_ }
        }
        if($CertificatesToRemove.Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Certificate authorities are present in the tenant which are not included in the desired state -> DESIRED: These CAs should be removed:"
            $CertificatesToRemove | foreach { $DriftSummary += Write-Output `t$_ }
        }
    }
    else
    {
        $DriftSummary += Write-Output "No drift detected. The current state aligns with the desired state." 
    }

    $DriftSummary | foreach { Write-Host $_}
    
    Write-Host "===================================================================================================="

    # Summarize current state
    if($Iteration -gt 0) {
        Write-Host "----------------- Current State of Entra ID Certificate Authorities After Changes ------------------"
    }
    else {
        Write-Host "----------------- Current State of Entra ID Certificate Authorities Before Changes -----------------"
    }
    $CACounter = 0
    $CloudCertificateAuthorities | foreach { 
        Write-Host "[CA$CACounter]" "Issuer:" $_.Issuer "; IsRootAuthority:" $_.IsRootAuthority "; CRL:" $_.CertificateRevocationListUrl
        $CACounter+=1
    }

    Write-Host "===================================================================================================="
    if($DriftCounter -gt 0)
    {
        Write-Host "DRIFT DETECTED: The current state does not align with the desired state."
    }
    else
    {
        Write-Host "NO DRIFT DETECTED: The current state aligns with the desired state."
    }
    Write-Host "===================================================================================================="

    $Iteration += 1
    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "CertificatesToAddOrModify" = $CertificatesToAddOrModify; "CertificatesToRemove" = $CertificatesToRemove; "CloudCertificateSummary" = $CloudCertificateSummary; "DriftSummary" = $DriftSummary }

}