# Module: Emergency Accounts

**Required Permissions**:
- Directory.ReadWrite.All
- Group.ReadWrite.All

**Required PowerShell Modules**:
- Microsoft.Graph.Identity.SignIns
- Microsoft.Graph.Identity.DirectoryManagement
- Microsoft.Graph.Users
- Microsoft.Graph.Groups
- Az.KeyVault

## Public Functions

### Function: New-EmergencyAccounts

**Setting Location**: Azure Portal > Entra ID > Users

**Input Variables**:
- UserPrincipalName: The UPN of the emergency access account to be created.
- DisplayName: The Display Name of the emergency access account to be created.
- PasswordLength: The password length of the emergency access account to be created.
- ExpireDays: The period after which the secret in Azure Key Vault which stores the emergency access account's password will be expired.
- VaultName: The name of the Azure Key Vault in which the emergency access account's password should be stored as a secret.
- KeyVaultSecretName: They name of the Azure Key Vault secret which will store the emergency access account's password.
- AssignGlobalAdmin: Specifies whether Global Admin will be automatically assigned to the emergency access account. This is disabled by default, as automatic assignment of Global Admin privileges requires highly privileged access to be granted to the deployment service principal.

**Description**: Deploys an Entra ID emergency access account, adds it to an emergency access group and saves its password as a secret in a specified key vault. Parameters for the emergency access account can be provided manually or integrated with another tool such as Terraform to pass required values.