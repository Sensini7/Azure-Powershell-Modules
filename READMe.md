# Module: Entra ID Password Expiration Policy

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Directory.Read.All
- User.ReadWrite.All

**Required PowerShell Modules**:
- Microsoft.Graph.Users

## Public Functions

### Function: Set-PasswordExpirationPolicy

**Setting Location in Azure Portal**: Azure Active Directory > Users > User > Properties > Password Policy 

**Input Variables**:
- PASSWORD_POLICY_SETTING: The desired password policy setting for Entra ID. Options include "None" or "DisablePasswordExpiration".

**Description**:
Configures the Entra ID password policy to ensure that user passwords either expire or never expire across the organization based on desired policy passed at runtime. This function modifies the password settings to match the desired policy configuration. Future enhancements may expand to adjust password policy settings.

## Private Functions

### Function: Compare-PasswordExpirationPolicy

**Description**: Compares the current and desired state of the password expiration policy to identify drift and determine if a change is necessary to align with the desired settings.
- Current state is queried directly from Entra ID using PowerShell, utilizing the appropriate Microsoft Graph API commands.
- Desired state is specified through the PASSWORD_POLICY_SETTING variable.

**Properties Compared**:
- PASSWORD_POLICY_SETTING
  - Policies to be Added: Users or groups that do not have the password expiration policy configured in the current state but require it in the desired state.
  - Policies to be Modified: Users or groups with a password expiration policy that does not align with the desired policy setting.
  
## Usage

To use this module, ensure that you have the required permissions and PowerShell modules installed. Execute the `Set-PasswordExpirationPolicy` function with the appropriate input variables to configure the password expiration policy for Entra ID.

## Future Enhancements

- Support for additional password policy settings.
- Integration with other security and identity management features in Entra ID.