function Update-X509CertificateAuthMethod {
    param (
        [Parameter (Mandatory = $true)]
        [string[]] $EnabledMethods,

        [Parameter (Mandatory = $false)]
        [string[]] $DisabledMethods,

        [Parameter(Mandatory = $true)]
        [hashtable[]] $CertificateUserBindings,
        
        [Parameter(Mandatory = $true)]
        [hashtable] $AuthenticationModeConfiguration,

        [Parameter(Mandatory = $false)]
        [hashtable[]] $X509CertificateIncludeTargets,

        [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
        [switch] $ExecuteChange 
    )

    $CurrentMethod = "X509Certificate"
    $IncludeTargets = $X509CertificateIncludeTargets

    # Compile standard parameters
    $params = Get-StandardAuthMethodParameters
    $ParamState = $params.state
    $IncludeTargets = $params.includeTargets

    # Compile parameters object for setting the desired configuration
    $params["certificateUserBindings"] = $CertificateUserBindings
    $params["authenticationModeConfiguration"] = $authenticationModeConfiguration

    # Perform standard pre-checks
    $PreCheckResults = Get-StandardAuthMethodPrechecks
    if($PreCheckResults -eq 1) {return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary}

    # Compile current authentication method settings
    Write-Host "Now retrieving authentication method configuration for authentication method $CurrentMethod."
    $CloudAuthenticationMethodConfiguration = (Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod)

    # Compile current include targets
    Write-Host "Now retrieving current include targets for authentication method $CurrentMethod."
    $CloudIncludeTargets = $CloudAuthenticationMethodConfiguration.AdditionalProperties.includeTargets

    ### Compile desired settings specific to this auth method ###
    # Compile desired AuthenticationMode settings
    Write-Host "Now compiling desired X509 AuthenticationMode settings."
    $X509CertificateAuthenticationDefaultMode = $AuthenticationModeConfiguration.x509CertificateAuthenticationDefaultMode
    $X509CertificateDefaultRequiredAffinityLevel = $AuthenticationModeConfiguration.x509CertificateDefaultRequiredAffinityLevel

    # Compile desired AuthenticationMode rules
    Write-Host "Now compiling desired authentication mode rule settings."
    $AuthenticationModeRules = $AuthenticationModeConfiguration.rules
    $AuthenticationModeRuleSummary = @()
    foreach($AuthenticationModeRule in $AuthenticationModeRules)
    {
        $AuthenticationModeRuleSettings = @{
            "Identifier" = $AuthenticationModeRule.identifier
            "x509CertificateRuleType" = $AuthenticationModeRule.x509CertificateRuleType
            "x509CertificateAuthenticationMode" = $AuthenticationModeRule.x509CertificateAuthenticationMode
            "x509CertificateRequiredAffinityLevel" = $AuthenticationModeRule.x509CertificateRequiredAffinityLevel
            "x509CertificateUniqueId" = $AuthenticationModeRule.x509CertificateRuleType+":"+$AuthenticationModeRule.identifier
            "x509CertificateAuthenticationModeHash" = $AuthenticationModeRule.x509CertificateRuleType+":"+$AuthenticationModeRule.identifier+":"+$AuthenticationModeRule.x509CertificateAuthenticationMode
            "x509CertificateRequiredAffinityLevelHash" = $AuthenticationModeRule.x509CertificateRuleType+":"+$AuthenticationModeRule.identifier+":"+$AuthenticationModeRule.x509CertificateRequiredAffinityLevel
        }
        $AuthenticationModeRuleSummary += $AuthenticationModeRuleSettings
    }

    # Compile desired certificate user bindings settings
    Write-Host "Now compiling desired certificate user binding settings."
    $CertificateUserBindingSummary = @()
    foreach($CertificateUserBinding in $CertificateUserBindings)
    {
        $CertificateUserBindingSettings = @{
            "X509CertificateField" = $CertificateUserBinding.x509CertificateField
            "UserProperty" = $CertificateUserBinding.userProperty
            "Priority" = $CertificateUserBinding.priority
            "UserPropertyHash" = $CertificateUserBinding.x509CertificateField+":"+$CertificateUserBinding.userProperty
            "PriorityHash" = $CertificateUserBinding.x509CertificateField+":"+$CertificateUserBinding.priority
        }
        $CertificateUserBindingSummary += $CertificateUserBindingSettings
    }

    # Perform standard checks
    $StandardPreResults = Get-StandardAuthMethodChecks
    $IncludeTargetsToAdd = $StandardPreResults["IncludeTargetsToAdd"]
    $IncludeTargetsToRemove = $StandardPreResults["IncludeTargetsToRemove"]
    $DriftCounter = $StandardPreResults["DriftCounter"]

    # Perform pre-checks specific to this auth method
    $PreResults = Compare-X509CertificateAuthMethod
    $Iteration = $PreResults["Iteration"]
    $CloudCertificateUserBindingSummary = $PreResults["CloudCertificateUserBindingSummary"]
    $CloudAuthenticationModeRuleSummary = $PreResults["CloudAuthenticationModeRuleSummary"]
    $DriftCounter = $PreResults["DriftCounter"]
    $DriftSummary = $PreResults["DriftSummary"]
    
    # End the function if this is a drift detection run
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
        if($DriftCounter -gt 0) {

            # Calculate missing user binding settings
            $MissingBindingSettings = @()
            foreach($CloudCertificateUserBinding in $CloudCertificateUserBindingSummary)
            {
                $CloudX509CertificateField = $CloudCertificateUserBinding.CloudX509CertificateField
                $CloudUserPropertyHash = $CloudCertificateUserBinding.CloudUserPropertyHash
                if($CertificateUserBindingSummary.UserPropertyHash -NotContains $CloudUserPropertyHash)
                {
                    Write-Host "An X509 user attribute mapping is currently present in the tenant for mapping $CloudUserPropertyHash but is not included in the desired configuration."
                    $MissingBindingSettings += $CloudUserPropertyHash
                }
            }
            if($MissingBindingSettings.Count -gt 0)
            {
                Write-Host "WARNING: At least one X509 user attribute mapping currently configured in the Entra ID tenant is not present in the list of desired settings. To avoid unintentional removal of X509 user attribute mappings, no changes to X509 user attribute mappings will be made."
                Write-Host "Verify that the list of X509 user attribute mappings is accurate. If it is, manually delete the X509 user attribute mappings from Entra ID that are no longer needed before re-running this script."
                Write-Host "These are the X509 user attributes currently configured in Entra ID which are not present in the desired configuration:"
                $MissingBindingSettings | foreach { Write-Host $_ }
                return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
            }
            else
            {
                Write-Host "There are no user attribute mappings configured in Entra ID which are not present in the desired configuration. This is expected. Proceeding."
            }

            # Calculate missing authentication mode rules
            $MissingRuleSettings = @()
            foreach($CloudAuthenticationModeRule in $CloudAuthenticationModeRuleSummary)
            {
                $CloudIdentifier = $CloudAuthenticationModeRule.CloudIdentifier
                $Cloudx509CertificateRuleType = $CloudAuthenticationModeRule.Cloudx509CertificateRuleType
                $Cloudx509CertificateUniqueId = $CloudAuthenticationModeRule.Cloudx509CertificateUniqueId
                if($AuthenticationModeRuleSummary.x509CertificateUniqueId -NotContains $Cloudx509CertificateUniqueId)
                {
                    Write-Host "An X509 authentication mode rule of type $Cloudx509CertificateRuleType with ID $CloudIdentifier is currently configured which is not present in the list of desired settings. To avoid unintentional removal of X509 authentication mode rules, no changes to authentication mode X509 rules will be made."
                    $MissingRuleSettings += $Cloudx509CertificateUniqueId
                }
            }
            if($MissingRuleSettings.Count -gt 0)
            {
                Write-Host "WARNING: At least one X509 authentication mode rule currently configured in the Entra ID tenant is not present in the list of X509 authentication mode rules. To avoid unintentional removal of X509 authentication mode rules, no changes to X509 authentication mode rules will be made."
                Write-Host "Verify that the list of X509 authentication mode rules is accurate. If it is, manually delete the X509 authentication mode rules from Entra ID that are no longer needed before re-running this script."
                Write-Host "These are the rule types and IDs of the X509 authentication mode rules currently configured in Entra ID which are not present in the desired configuration in the format of [RuleType]:[Rule ID]:"
                $MissingRuleSettings | foreach { Write-Host $_ }
                return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
            }
            else
            {
                Write-Host "There are no X509 authentication mode rules configured in Entra ID which are not present in the desired configuration. This is expected. Proceeding."
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

            # Update method to desired state and check if it was successful
            Write-Host "----------------------------------------------------------------------------------------------------"
            Write-Host "Now deploying desired configuration to authentication method $CurrentMethod."
            $HideOutput = Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod -BodyParameter $params -ErrorAction Stop
            Write-Host "Now performing post-configuration checks for authentication method $CurrentMethod."
            Write-Host "----------------------------------------------------------------------------------------------------"
                        
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
            $PostResults = Compare-X509CertificateAuthMethod
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