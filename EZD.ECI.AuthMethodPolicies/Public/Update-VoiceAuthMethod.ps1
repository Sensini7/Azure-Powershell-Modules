function Update-VoiceAuthMethod {
    
    param (
        [Parameter (Mandatory = $true)]
        [string[]] $EnabledMethods,

        [Parameter (Mandatory = $false)]
        [string[]] $DisabledMethods,

        [Parameter(Mandatory = $false)]
        [hashtable[]] $VoiceIncludeTargets,

        [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
        [switch] $ExecuteChange 
    )

    $CurrentMethod = "Voice"
    $IncludeTargets = $VoiceIncludeTargets

    # Compile standard parameters
    $params = Get-StandardAuthMethodParameters
    $ParamState = $params.state
    $IncludeTargets = $params.includeTargets

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
    $PreResults = Compare-VoiceAuthMethod
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
            $PostResults = Compare-VoiceAuthMethod
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