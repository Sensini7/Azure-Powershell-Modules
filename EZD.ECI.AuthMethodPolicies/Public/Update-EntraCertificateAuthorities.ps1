function Update-EntraCertificateAuthorities {

    param (
            [Parameter (Mandatory = $true)]
            [string] $IcamKeyVault,

            [Parameter (Mandatory = $true)]
            [string] $TenantId,

            [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
            [switch] $ExecuteChange
    )

    # Generate a list of desired root and intermediate certificate authorities
    $CertificateList = Get-AzKeyVaultSecret -VaultName $IcamKeyVault | Where {$_.Tags -and ($_.Tags["type"] -eq "intermediate-certificate" -or $_.Tags["type"] -eq "root-certificate") } | Select Name,Tags
    $CertificateAuthorities = @()
    $CertificateSummary = @()
    $InvalidAuthorityList = @()
    $InvalidAuthorityCounter = 0

    foreach($Certificate in $CertificateList)
    {
        $CertificateName = $Certificate.Name
        $CertificateType = $Certificate.Tags.type
        $CertificateRevocationListUrl = $Certificate.Tags.crl
        $CertificateFileBase64 = Get-AzKeyVaultSecret -VaultName $IcamKeyVault -Name $CertificateName -AsPlainText
        $Certificate = [Convert]::FromBase64String($CertificateFileBase64)
        if($CertificateType -eq "root-certificate")
        {
            $IsRootAuthority = $true
            $AuthorityTypeLabel = "Root"
        }
        else
        {
            if($CertificateType -eq "intermediate-certificate")
            {
                $IsRootAuthority = $false
                $AuthorityTypeLabel = "Intermediate"
            }
            else
            {
                $IsRootAuthority = $null
                $InvalidAuthorityCounter += 1
                $InvalidAuthorityList += $CertificateName
            }
        }
        $CertificateAuthority = @{
            "certificate" = $Certificate
            "CertificateRevocationListUrl" = $CertificateRevocationListUrl
            "isRootAuthority" = $IsRootAuthority
        }
        $CertificateAuthorities += $CertificateAuthority

        # Generate a list of desired root and intermediate certificate thumbprints
        $CertificateBytes = [Convert]::FromBase64String($CertificateFileBase64)
        $CertificateX509 = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CertificateBytes)
        $CertificateThumbprint = $CertificateX509.Thumbprint
        $CertificateDetails = @{
            "CertificateName" = $CertificateName
            "CertificateThumbprint" = $CertificateThumbprint
            "AuthorityTypeLabel" = $AuthorityTypeLabel
            "CertificateRevocationListUrl" = $CertificateRevocationListUrl
            "AuthorityHash" = $CertificateThumbprint+":"+$AuthorityTypeLabel
            "CrlHash" = $CertificateThumbprint+":"+$CertificateRevocationListUrl
        }
        $CertificateSummary += $CertificateDetails
    }

    # If any of the certificates read from key vault did not have a valid certificate type, end the script with an error
    if($InvalidAuthorityCounter -gt 0)
    {
        Write-Host "ERROR: The following certificates had invalid certificate type entries in Key Vault:"
        $InvalidAuthorityList | foreach { Write-Host `t$_ }
        return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
    }

    Write-Host "Goal: Ensure the following certificate authorities are deployed with the desired settings in tenant with ID $TenantID :"
    $CertificateList | foreach { Write-Host "`t$($_.Name)" }

    # Perform pre-execution checks
    $PreResults = Compare-EntraCertificateAuthorities
    $Iteration = $PreResults["Iteration"]
    $DriftCounter = $PreResults["DriftCounter"]
    $CertificatesToAddOrModify = $PreResults["CertificatesToAddOrModify"]
    $CertificatesToRemove = $PreResults["CertificatesToRemove"]
    $CloudCertificateSummary = $PreResults["CloudCertificateSummary"]
    $DriftSummary = $PreResults["DriftSummary"]

    # Execute the change or end the function if this is a drift detection run
    if (-Not ($ExecuteChange)) {
        Write-Host "This is a drift detection run. No changes will be made."
		if($DriftCounter -gt 0)
		{
			return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
		}
        else
		{
			return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
		}
    }
    else
    {
        # Execute the change if drift was detected
        if($DriftCounter -gt 0) 
        {
            # Evaluate whether any existing certificate authorities configured in Entra ID are not present in Key Vault
            if($CertificatesToRemove.Count -gt 0)
            {
                Write-Host "WARNING: At least one certificate authority currently configured in the Entra ID tenant is not present in the list of desired certificate authorities in Key Vault. To avoid unintentional removal of certificate authorities, no changes to certificate authorities will be made."
                Write-Host "Verify that the list of certificate authorities in Key Vault is accurate. If it is, manually delete the certificate authority from Entra ID that is no longer needed before re-running this script."
                Write-Host "These are the thumbprints of the certificate authorities currently configured in Entra ID which are not present in Key Vault:"
                $CertificatesToRemove | foreach { Write-Host `t$_ }
                return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
            }
            else
            {
                Write-Host "There are no certificates configured in Entra ID which are not present in Key Vault. This is expected. Proceeding."
            }

            # Configure the appropriate certificate authority settings
            Write-Host "----------------------------------------------------------------------------------------------------"
            Write-Host "Now configuring certificate authorities in Entra ID. These certificate authorities will be added or updated:"
            $CertificatesToAddOrModify | foreach { Write-Host `t$_ }
            $HideOutput = New-MgOrganizationCertificateBasedAuthConfiguration -OrganizationId $TenantId -CertificateAuthorities $CertificateAuthorities
            Write-Host "----------------------------------------------------------------------------------------------------"

            # Perform post-execution checks
            $PostResults = Compare-EntraCertificateAuthorities
            $DriftCounter = $PostResults["DriftCounter"]
			if($DriftCounter -eq 0)
			{
				Write-Host "Settings are configured as desired. The change was successful."
				return Get-ReturnValue -ExitCode 3 -DriftSummary $DriftSummary
			}
			else
			{
				Write-Host "WARNING: Settings did not pass post-execution checks. The change was not successful."
				return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
			}
		}
		elseif ($DriftCounter -eq 0)
		{
			Write-Host "No change is required. Settings are already configured as desired."
			return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
		}
		else
		{
			Write-Host "WARNING: Unable to complete post-execution validation."
			return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
		}

	}

}