function Update-Fido2AuthMethod {
    
    param (
        [Parameter (Mandatory = $true)]
        [string[]] $EnabledMethods,

        [Parameter (Mandatory = $false)]
        [string[]] $DisabledMethods,

        [Parameter(Mandatory = $false)]
        [hashtable[]] $Fido2IncludeTargets,

        [Parameter(Mandatory = $false)]
        [hashtable[]] $Fido2AuthSettings,

        [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
        [switch] $ExecuteChange  
    )

    $CurrentMethod = "Fido2"
    $IncludeTargets = $Fido2IncludeTargets

    # Define variables for settings specific to the authentication method
    $isSelfServiceRegistrationAllowed = $Fido2AuthSettings.isSelfServiceRegistrationAllowed
    $isAttestationEnforced = $Fido2AuthSettings.isAttestationEnforced
    $keyRestrictionsInput = ConvertTo-HashTable $Fido2AuthSettings.keyRestrictions
    $aaGuids = $keyRestrictionsInput.aaGuids
    $enforcementType = $keyRestrictionsInput.enforcementType
    $isEnforced = $keyRestrictionsInput.isEnforced

    # Compile standard parameters
    $params = Get-StandardAuthMethodParameters
    $ParamState = $params.state
    $IncludeTargets = $params.includeTargets

    # Compile parameters object for setting the desired configuration
    $params["isSelfServiceRegistrationAllowed"] = $isSelfServiceRegistrationAllowed
    $params["isAttestationEnforced"] = $isAttestationEnforced
    $params["keyRestrictions"] = $keyRestrictionsInput    

    # Perform standard pre-checks
    $PreCheckResults = Get-StandardAuthMethodPrechecks
    if($PreCheckResults -eq 1) {return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary}

    # Compile current authentication method settings
    $CloudAuthenticationMethodConfiguration = (Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod)

    # Compile current include targets
    Write-Host "Now retrieving current include targets for authentication method $CurrentMethod."
    $CloudIncludeTargets = $CloudAuthenticationMethodConfiguration.AdditionalProperties.includeTargets

    # Perform standard checks
    $StandardPreResults = Get-StandardAuthMethodChecks
    $IncludeTargetsToAdd = $StandardPreResults["IncludeTargetsToAdd"]
    $IncludeTargetsToRemove = $StandardPreResults["IncludeTargetsToRemove"]
    $DriftCounter = $StandardPreResults["DriftCounter"]

    # Perform pre-checks specific to this auth method
    $PreResults = Compare-Fido2AuthMethod
    $Iteration = $PreResults["Iteration"]
    $DriftCounter = $PreResults["DriftCounter"]
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
            # Check for missing authenticator attestation GUIDs
            $MissingAaguids = @()
            $CloudAaguids = $CloudAuthenticationMethodConfiguration.AdditionalProperties.keyRestrictions.aaGuids
            foreach($CloudAaguid in $CloudAaguids)
            {
                if(($aaGuids -NotContains $CloudAaguid) -and ($isEnforced -eq $true))
                {
                    Write-Host "Authenticator attestation GUID $CloudAaguid is currently configured which is not present in the list of desired settings. To avoid unintentional loss of access, no changes to authenticator attestation GUIDs will be made."
                    $MissingAaguids += $CloudAaguid
                }
            }
            if($MissingAaguids.Count -gt 0)
            {
                Write-Host "WARNING: At least one authenticator attestation GUID currently configured in the authenticator attestation GUIDs is not present in the list of desired GUIDs. To avoid unintentional loss of access, no changes to GUIDs will be made."
                Write-Host "Verify that the list of authenticator attestation GUIDs is accurate. If it is, manually remove the authenticator attestation GUIDs from Entra ID that are no longer needed before re-running this script."
                Write-Host "These are the authenticator attestation GUIDs of the security key types currently configured in the authenticator attestation GUID list which are not present in the desired configuration:"
                $MissingAaguids | foreach { Write-Host $_ }
                return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
            }
            else
            {
                Write-Host "There are no authenticator attestation GUIDs configured in GUID list which are not present in the desired configuration. This is expected. Proceeding."
            }

                # Check for missing include targets
            $MissingIncludeTargets = Get-MissingIncludeTargets
            if($MissingIncludeTargets -eq 1) {return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary}

            # Reset variables before reusing them
            $CloudIncludeTargets = $null
            $CloudAuthenticationMethodConfiguration = $null
            $IncludeTargetsToAdd = $null
            $IncludeTargetsToRemove = $null
            $DriftCounter = $null

            # Update method to desired state and checking if it was successful
            Write-Host "-----------------------------------------------------------------------------------------------------"
            Write-Host "Now deploying desired configuration to authentication method $CurrentMethod."
            $HideOutput = Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod -BodyParameter $params -ErrorAction Stop
            Write-Host "Now performing post-configuration checks for authentication method $CurrentMethod."
            Write-Host "-----------------------------------------------------------------------------------------------------"
                        
            # Compile current authentication method settings
            $CloudAuthenticationMethodConfiguration = (Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod)

            # Compile current include targets
            Write-Host "Now retrieving current include targets for authentication method $CurrentMethod."
            $CloudIncludeTargets = $CloudAuthenticationMethodConfiguration.AdditionalProperties.includeTargets

            # Perform standard checks
            $StandardPostResults = Get-StandardAuthMethodChecks
            $IncludeTargetsToAdd = $StandardPostResults["IncludeTargetsToAdd"]
            $IncludeTargetsToRemove = $StandardPostResults["IncludeTargetsToRemove"]
            $DriftCounter = $StandardPostResults["DriftCounter"]
            
            # Evaluate drift from the desired configuration
            $PostResults = Compare-Fido2AuthMethod
            $DriftCounter = $PostResults["DriftCounter"]
            $DriftSummary = $PostResults["DriftSummary"]
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