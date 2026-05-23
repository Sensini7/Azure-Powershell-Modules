# Module: Authentication Method Policies

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Organization.ReadWrite.All
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns
- Az.Accounts
- Az.KeyVault

**Include Targets**: All authentication methods have an include targets variable that is specified in the format [{"targetType":"group","id":"**group 1 object id**","isRegistrationRequired":false},{"targetType":"group","id":"**group 2 object id**","isRegistrationRequired":false}]. For brevity, this format is not repeated in the description of each function.

If the Include Targets variable is not populated for an authentication method, it is assumed that the Include Targets for the authentication method should be set to "all_users." This prevents the function from inadvertently decreasing the scope of existing Include Targets, which could prevent users from being able to sign into Entra ID.

## Public Functions

### Function: Update-EntraCertificateAuthorities

**Setting Location in Azure Portal**: Entra ID > Security > Certificate Authorities

**Input Variables**:
- ICAM_KEY_VAULT_NAME: The name of the Azure Key Vault which stores certificate authority information. The certificate authority object name, certificate revocation list and CA type (intermediate vs. root) are stored as secrets in the specified key vault. The specified key vault must be present in the subscription identified in the AZURE_SUBSCRIPTION_ID variable called in the Connect-AzAccount element of the Authentication Methods workflow.
- AZURE_TENANT_ID: The tenant ID of the Entra ID tenant that is being configured. The certificate authorities will be configured in this tenant to support X509 authentication. This is used in the function as well as its parent workflow.

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Organization.ReadWrite.All

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns
- Az.Accounts
- Az.KeyVault

**Description**:
Updates Entra ID Certificate Authorities. These are used by the X509 Certificate-Based Authentication method in Entra ID.

The desired state certificate authority configuration is determined based upon secrets which are populated in the key vault specified in the ICAM_KEY_VAULT_NAME variable, which must reside in the Azure subscription specified in the AZURE_SUBSCRIPTION_ID variable. 

Each certificate authority to be deployed into Entra ID has one associated secret in the key vault. Secrets populated in this key vault must include the following properties:
- Name: This is used by the function to track configuration of the certificate authority in the logs. This value is used for logging only and is not used to configure any properties in Entra ID. This should be set to a human-readable value which clearly maps to the certificate authority being configured. For example, if the CRLs for the certificate authorities are in the format https://www.verification.com/CRLs/**CertificateAuthorityName**.crl, the **CertificateAuthorityName** value from the CRL would be appropriate for this property. 
- Value: The Base64 certificate value of the CA being configured in the tenant. It is calculated by storing the full certificate value in bytes in a variable and converting it to a Base64 value, using the PowerShell cmdlet **[System.Convert]::ToBase64String($CertificateInBytes)**. $CertificateInBytes can be retrieved either from a file (.cer) or an existing certificate in Entra ID. 
  - To retrieve from a file: **Get-Content -Encoding byte "Certificate.cer"**
  - To retrieve from an existing Entra ID Certificate Authority: **(Get-MgOrganizationCertificateBasedAuthConfiguration -OrganizationId $TenantId).CertificateAuthorities.Certificate**
- crl (tag): A tag on the certificate authority secret with the exact key "crl". The value of the tag should be the URL of the certificate's certificate revocation list.
- type (tag): A tag on the certificate authority secret with the exact key "type". The value of the tag should be "intermediate-certificate" if the certificate authority to be deployed is an intermediate CA and "root-certificate" if the certificate authority to be deployed is a root CA.

The function deploys one certificate authority per properly configured secret in the key vault specified in the ICAM_KEY_VAULT_NAME variable. The function will only **add** certificate authorities. By design, it will **not remove** certificate authorities. This is because removal of a certificate authority is potentially a highly disruptive event in an environment which is dependent upon X509 Certificate-Based Authentication as its primary form of authentication. Instead, if a certificate authority is found to be configured in the Entra ID tenant which does not have an associated secret in the key vault, a warning will be produced instructing the error to either manually remove the unwanted certificate authority or add the appropriate secret to the key vault.

---

### Function: Update-EmailAuthMethod

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods

**Input Variables**:
- EMAIL_INCLUDE_TARGETS: List of include targets for whom the authentication method will be enabled if the authentication method state is set to enabled. 

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the email authentication method within Entra ID. Currently, the only settings for this authentication method supported for configuration by this module are the authentication method state (enabled / disabled) and include targets.

---

### Function: Update-Fido2AuthMethod

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods
**Input Variables**:
- FIDO2_INCLUDE_TARGETS: List of include targets for whom the authentication method will be enabled if the authentication method state is set to enabled. 
- FIDO2_AUTH_SETTINGS: List of FIDO2 authentication method settings and their values that is specified in the format [ { "isAttestationEnforced": $boolean, "isSelfServiceRegistrationAllowed": $boolean }, { "keyRestrictions": { "isEnforced": $boolean, "enforcementType": "allow / block", "aaGuids": [ "**aaguid value 1**", "**aaguid value 2**" ] } } ]. A list of supported AAGUIDs is available from Microsoft here: https://learn.microsoft.com/en-us/entra/identity/authentication/concept-fido2-hardware-vendor#fido2-security-keys-eligible-for-attestation-with-microsoft-entra-id

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the FIDO2 authentication method within Entra ID.

---

### Function: Update-MicrosoftAuthenticatorAuthmethod

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods

**Input Variables**:
- MSFTAUTH_INCLUDE_TARGETS: List of include targets for whom the authentication method will be enabled if the authentication method state is set to enabled. 

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the Microsoft Authenticator authentication method within Entra ID. Currently, the only settings for this authentication method supported for configuration by this module are the authentication method state (enabled / disabled) and include targets.

---

### Function: Update-SmsAuthMethod

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods

**Input Variables**:
- SMS_INCLUDE_TARGETS: List of include targets for whom the authentication method will be enabled if the authentication method state is set to enabled. 

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the SMS authentication method within Entra ID. Currently, the only settings for this authentication method supported for configuration by this module are the authentication method state (enabled / disabled) and include targets.

---

### Function: Update-SoftwareOathAuthMethod

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods

**Input Variables**:
- SOFTOATH_INCLUDE_TARGETS: List of include targets for whom the authentication method will be enabled if the authentication method state is set to enabled. 

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the Software Oath authentication method within Entra ID. Currently, the only settings for this authentication method supported for configuration by this module are the authentication method state (enabled / disabled) and include targets.

---

### Function: Update-TemporaryAccessPassAuthMethod

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods

**Input Variables**:
- TAP_INCLUDE_TARGETS: List of include targets for whom the authentication method will be enabled if the authentication method state is set to enabled. 
- TAP_AUTH_DEFAULT_LIFETIME_IN_MINUTES: Sets the default lifetime of TAP credentials. Integer.
- TAP_AUTH_DEFAULT_LENGTH: Sets the default length (number of characters) of TAP credentials. Integer.
- TAP_AUTH_MIN_LIFETIME_IN_MINS: Sets the minimum lifetime (in minutes) of TAP credentials. Integer.
- TAP_AUTH_MAX_LIFETIME_IN_MINS: Sets the maximum lifetime (in minutes) of TAP credentials. Integer.
- TAP_AUTH_IS_USABLE: Specifies whether TAP credentials can be used more than once within their specified lifetimes. Boolean.

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the Temporary Access Pass authentication method within Entra ID.

---

### Function: Update-VoiceAuthMethod

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods

**Input Variables**:
- VOICE_INCLUDE_TARGETS: List of include targets for whom the authentication method will be enabled if the authentication method state is set to enabled. 

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the Voice authentication method within Entra ID. Currently, the only settings for this authentication method supported for configuration by this module are the authentication method state (enabled / disabled) and include targets.

---

### Function: Update-X509AuthMethod

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods

**Input Variables**:
- CBA_INCLUDE_TARGETS: List of include targets for whom the authentication method will be enabled if the authentication method state is set to enabled. 
- CBA_AUTH_MODE_CONFIG: Sets the default authentication mode configuration, accepted issuers and issuer settings for X509 Certificate-Based AUthentication. Expressed as a complex JSON object.
- CBA_USER_BINDINGS: Sets the bindings of certificate fields to user attributes for the X509 Certificate-Based Authentication method. Expressed as a complex JSON object.

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the X509 Certificate-Based Authentication method within Entra ID.

---

### Function: Update-AuthMethodMigrationState

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods

**Input Variables**:
- AUTH_POLICY_MIGRATION_STATE: Specifies whether the authentication policy migration state should be set to preMigration, inProgress or migrationComplete. **preMigration** means that legacy authentication method settings for SSPR and MFA should be used. **inProgress** means that legacy and centralized SSPR and MFA policies are in a coexistence state. **migrationComplete** means that legacy SSPR and MFA policies have been migrated to use Microsoft's recommended centralized authentication policy.

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates the authentication method migration state to the specified value. This determines whether legacy SSPR and MFA settings are respected by the tenant or control over SSPR and MFA behavior has been fully transferred to Microsoft's recommended centralized authentication policy.

## Private Functions

### About: Compare Functions

**Universal Behaviors**

Compare functions query the current state of settings with the desired state to determine whether a change is necessary to bring the setting into alignment with the desired state. Compare functions are paired public functions in a 1:1 relationship. Each public function calls its associated Compare function twice: once before changes and once after changes (if the Public function is run in Deployment mode).

The Compare function execution before execution of changes instructs the Public function on whether there is drift in the configuration of the observed setting. Each configuration within the setting which is out of alignment with the desired state increments a **$DriftCounter** variable by 1. After evaluating all configurations within a setting, if the $DriftCounter variable is greater than 0, then the public function detects drift in the setting.

All detected configurations which have drifted from the desired state are stored in an array called **$DriftSummary**. The $DriftSummary variable captures a running log of all instances of drift detected during execution of the Compare function. This is replayed to the workflow logs using a Write-Host cmdlet. The value of the $DriftSummary variable is also passed to the public function as an output which is returned in the ExitLogs variable upon completion of execution when the workflow is executed in Drift Detection mode.

**Usage**

When the workflow is executed in Drift Detection mode, the value of the $DriftCounter variable determines the exit code of its associated Public function. If $DriftCounter is greater than 0 when the workflow is executed in Drift Detection mode, an exit code of 2 is produced, which indicates that drift was detected in Drift Detection mode. This produces a signal to the CI/CD pipeline which can be used to automatically open a ticket and / or send an alert, such as an email. This also passes the value of the $DriftSummary variable to the function's ExitLogs, so that it can be read and included in any tickets or alerts.

When the workflow is executed in Deployment mode, the value of the $DriftCounter variable sends the Public function two signals, depending upon whether the Compare function is run before or after the change is executed. 
- **In the first execution of the Compare function**, the value of the $DriftCounter variable instructs the public function to make a change. If the value of the $DriftCounter variable greater than 0, then the public function proceeds past the initial Compare function, makes the change and runs the Compare function again to confirm the change was successful. If the value of the $DriftCounter variable is equal to 0, then the public function reports that no drift was detected and ceases execution without attempting to make any changes or running the Compare function a second time.
- **In the second execution of the Compare function**, the value of the $DriftCounter variable instructs the public function on whether the change was successful. If the value of the $DriftCounter variable is greater than 0 after the change, then the Public function returns an error with exit code 1 notifying the operator that the change was not successful. If the value of the $DriftCounter variable is equal to 0 after the change, then the Public function returns a success message with exit code 3. A Compare function only executes a second time if the following conditions are met: (1) the workflow is run in Deployment mode and (2) drift is detected.

**Additional Behaviors**

Some Compare functions also produce additional signals used by their associated Public functions, such as $ReturnVariable variables which instruct the Public function that the current and desired state could not be successfully compared and to end the workflow execution with an error (exit code 1).

---

### Function: Compare-EntraCertificateAuthorities

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- Current state is queried directly from Entra ID using PowerShell, using the **(Get-MgOrganizationCertificateBasedAuthConfiguration -OrganizationId $TenantId).CertificateAuthorities** cmdlet. 
- Desired state is based upon the secrets which are populated in the key vault specified in the ICAM_KEY_VAULT_NAME variable.

**Properties Compared**:
- Certificate authorities to add: Certificate authorities which are present in the desired state but not in the current state. Based upon analysis of certificate thumbprints.
- Certificate authorities to remove: Certificate authorities which are present in the current state but not in the desired state. Based upon analysis of certificate thumbprints.
- Certificate authorities to modify: Desired certificate authorities which are present in the current state but which have either their certificate authority type (intermediate / root) or CRL misconfigured.

---

### Function: Compare-EmailAuthMethod

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the value of the function's associated include targets variable, as well as the AUTH_METHODS_ENABLED and AUTH_METHODS_DISABLED variables.

**Properties Compared**:
- Authentication method state: The state of the authentication method (enabled / disabled).
- Authentication method include targets: The include targets, which define who can utilize the authentication method when it is in an enabled state.

---

### Function: Compare-Fido2AuthMethod

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the following variables: FIDO2_INCLUDE_TARGETS, FIDO2_AUTH_SETTINGS

**Properties Compared**:
- Authentication method state: The state of the authentication method (enabled / disabled).
- FIDO2_INCLUDE_TARGETS: The include targets, which define who can utilize the authentication method when it is in an enabled state.
- isSelfServiceRegistrationAllowed: If set to No, users can't register a passkey by using Security info, even if FIDO2 is enabled.
- isAttestationEnforced: Determines whether FIDO2 keys are validated against vendor attestation GUIDs.
- Key restrictions enabled: Determines whether there are restrictions enforced on FIDO2 keys based on attestation GUIDs.
- Authenticator Attestation GUIDs to add: Authenticator attestation GUIDs which are present in the desired state but not the current state.
- Authenticator Attestation GUIDs to remove: Authenticator attestation GUIDs which are present in the current state but not the desired state.

---

### Function: Compare-MicrosoftAuthenticatorAuthmethod

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the value of the function's associated include targets variable, as well as the AUTH_METHODS_ENABLED and AUTH_METHODS_DISABLED variables.

**Properties Compared**:
- Authentication method state: The state of the authentication method (enabled / disabled).
- Authentication method include targets: The include targets, which define who can utilize the authentication method when it is in an enabled state.

---

### Function: Compare-SmsAuthMethod

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the value of the function's associated include targets variable, as well as the AUTH_METHODS_ENABLED and AUTH_METHODS_DISABLED variables.

**Properties Compared**:
- Authentication method state: The state of the authentication method (enabled / disabled).
- Authentication method include targets: The include targets, which define who can utilize the authentication method when it is in an enabled state.

---

### Function: Compare-SoftwareOathAuthMethod

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the value of the function's associated include targets variable, as well as the AUTH_METHODS_ENABLED and AUTH_METHODS_DISABLED variables.

**Properties Compared**:
- Authentication method state: The state of the authentication method (enabled / disabled).
- Authentication method include targets: The include targets, which define who can utilize the authentication method when it is in an enabled state.

---

### Function: Compare-TemporaryAccessPassAuthMethod

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the following variables: TAP_INCLUDE_TARGETS, AUTH_METHODS_ENABLED, AUTH_METHODS_DISABLED, TAP_AUTH_DEFAULT_LIFETIME_IN_MINUTES, TAP_AUTH_DEFAULT_LENGTH, TAP_AUTH_MIN_LIFETIME_IN_MINS, TAP_AUTH_MAX_LIFETIME_IN_MINS, TAP_AUTH_IS_USABLE

**Properties Compared**:
- Authentication method state: The state of the authentication method (enabled / disabled).
- TAP_INCLUDE_TARGETS: The include targets, which define who can utilize the authentication method when it is in an enabled state.
- TAP_AUTH_DEFAULT_LIFETIME_IN_MINUTES: The default lifetime of TAP credentials.
- TAP_AUTH_DEFAULT_LENGTH: The default length (number of characters) of TAP credentials.
- TAP_AUTH_MIN_LIFETIME_IN_MINS: The minimum lifetime (in minutes) of TAP credentials.
- TAP_AUTH_MAX_LIFETIME_IN_MINS: The maximum lifetime (in minutes) of TAP credentials.
- TAP_AUTH_IS_USABLE: Specifies whether TAP credentials can be used more than once within their specified lifetimes.

---

### Function: Compare-VoiceAuthMethod

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the value of the function's associated include targets variable, as well as the AUTH_METHODS_ENABLED and AUTH_METHODS_DISABLED variables.

**Properties Compared**:
- Authentication method state: The state of the authentication method (enabled / disabled).
- Authentication method include targets: The include targets, which define who can utilize the authentication method when it is in an enabled state.

---

### Function: Compare-X509AuthMethod

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the following variables: AUTH_METHODS_ENABLED, AUTH_METHODS_DISABLED, CBA_INCLUDE_TARGETS, CBA_AUTH_MODE_CONFIG, CBA_USER_BINDINGS

**Properties Compared**:
- Authentication method state: The state of the authentication method (enabled / disabled).
- CBA_INCLUDE_TARGETS: The include targets, which define who can utilize the authentication method when it is in an enabled state.
- Default protection level: Sets default protection level to single- or multi-factor authentication.
- Required affinity binding: Sets the minimum required affinity level (low / high) for username binding rules.
- Authentication mode rules to add: Certificate issuer rules which are present in the desired state but not the current state. 
- Authentication mode rules to remove: Certificate issuer rules which are present in the current state but not the desired state.
- Authentication mode rules to modify: Certificate issuer rules which are present in the current state but which have either their authentication strength (single-factor authentication / multi-factor authentication) or affinity binding (low / high) misconfigured.
- Username binding rules to add: Username binding rules which are present in the desired state but not the current state.
- Username binding rules to remove: Username binding rules which are present in the current state but not the desired state.
- Username binding rules to modify: Rules which exist for a certificate fields in the desired state, but which are not mapped to the correct user attribute.

---

### Function: Compare-AuthMethodMigrationState

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- The current state is calculated within the function using the **(Get-MgPolicyAuthenticationMethodPolicy).PolicyMigrationState** cmdlet.
- Desired state is based upon the value of the AUTH_POLICY_MIGRATION_STATE variable.

**Properties Compared**:
- Authentication Method Migration Policy State: Determines whether legacy SSPR and MFA settings are respected by the tenant or control over SSPR and MFA behavior has been fully transferred to Microsoft's recommended centralized authentication policy.

---

### Function: Get-MissingIncludeTargets

**Description**: Calculates whether there are any include targets included in the current state which are not included in the desired state. Designed to break execution of a parent Public function if any missing include targets are found for authentication methods which have a desired state of enabled.

This function is called once in every Public function, during Deployment runs only. It executes before changes are made during Deployment runs, and stops the Public function from making changes to the authentication method if there are missing include targets. Because omission of include targets can impact the ability of users to authenticate into the tenant, this function requires that changes which would result in include targets being removed are performed manually before any automated configuration actions are performed.

**Exceptions**: This function allows configuration to proceed even if there are missing include targets identified in the following cases.
- If the desired state of the authentication method being configured is "disabled," as a reduction in include target scope for a disabled authentication method does not prevent users from signing into the tenant.
- If the desired include targets of the authentication method being configured includes "all_users." In this case, even if a previously targeted group is removed from the include targets, users will not be prevented from using the authentication method.

---

### Function: Get-StandardAuthMethodChecks

**Description**: Performs standard drift detection checks which are performed for all authentication methods, so that they do not need to be repeated in the Compare functions of each authentication method. If drift is detected, a $DriftCounter variable is incremented and returned to the parent Public function. The $DriftCounter variable is subsequently passed to its associated Compare function, which adds drift calculations specific to its associated authentication method.

If drift is detected on Include Targets, the appropriate drift calculation is also passed to the Compare function for presentation of a consolidated drift summary in the logs.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $CurrentMethod** cmdlet.
- Desired state is based upon the value of the function's associated include targets variable, as well as the AUTH_METHODS_ENABLED and AUTH_METHODS_DISABLED variables.

**Usage**

This function is intended to be called in conjunction with authentication method Compare functions. As such, it runs once during Drift Detection runs and twice during Deployment Runs. It is intended to be run immediately before the authentication method's Compare function.

**Properties Compared**:
- Authentication Method Include Targets: Calculates drift between current and desired Include Targets.
- Authentication Method State: Calculates drift between current and desired authentication method state (enabled / disabled).

---

### Function: Get-StandardAuthMethodParameters

**Description**: Builds the standard components of the $params object passed to the Update call of the authentication method Public functions. The Public function subsequently appends any required fields which are specific to the authentication method. Parameters included in the baseline $params object created by this function include:
- Data Type: The metadata string which must be included in the params object for an authentication methods Update call to properly process changes.
- State: The desired state of the authentication method (enabled / disabled).
- Include Targets: The desired list of include targets for the authentication method.
- ID: The name of the authentication method being configured.

---

### Function: Get-StandardAuthMethodPrechecks

**Description**: Performs standard pre-checks to avoid operator error in the variable configuration for the authentication method which could result in undesirable behaviors in execution. If the specified desired state fails any of the pre-checks, the Public function halts with exit code 1 (error) and the execution logs specify the failed test and recommended remediation. Standard pre-checks include the following.
- State (enabled / disabled) not specified for the authentication method.
- Authentication method included in **both** the enabled and disabled list.
- An authentication method type is specified which does not align with a valid Entra ID authentication method.

---

### Function: New-ParameterList

**Description**: Generates a list of parameters and their desired values and stores it in a hash table. This allows parameters to be dynamically passed to the Public function through splatting and makes it possible to make some parameters, such as Include Targets, optional. This is meant to reduce the number of variables operators must maintain within the git repository in cases where some authentication methods are not planned for be used, such as not requiring include groups to be specified if an authentication method will be disabled.

This is intended to be used by the git workflow which orchestrates the module, rather than by the functions of the module itself.