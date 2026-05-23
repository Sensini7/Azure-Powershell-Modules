# Module: Cross-Tenant Access

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.CrossTenantAccess

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

## Public Functions

### Function: New-CrossTenantSynchronization

**Setting Location**: Azure Portal > Entra ID > External Identities > Cross-Tenant Access Settings > Organizational Settings

**Input Variables**: 
- TargetTenants: List of tenants the user wants to create a B2B relationship with.
- Direction: Specifies the direction of the cross tenant access policy (inbound or outbound).
- BlockAll: Flag that specifies whether or not to block access to all applications.
- AllowedApps: Represents list of allowed applications for inbound and outbound access policy. Can be one of the following values: 
  - The unique identifier of the user, group, or application 
  - AllUsers 
  - AllApplications - Refers to any Microsoft cloud application. 
  - Office365 - Includes the applications mentioned as part of the Office365 suite.

**Description**:
Configures inbound or outbound access settings for cross-tenant synchronization, applicable to multiple target tenants. Enables partner access to resources across tenants by creating a policy object linked to the partner’s service principal. Updates cross-tenant access policy for existing relationships to reflect only changes. Manages external partner access rights to resources within a Microsoft 365 tenant.

### Function: Set-CrossTenantAccessSettingDefaults

**Setting Location**: Azure Portal > Entra ID > External Identities > Cross-Tenant Access Settings > Default Settings

**Input Variables**: This function has no input variables, as it currently only supports setting the default behavior of Entra B2B application access to "Blocked" for all users and applications. This means that organizations must have an explicitly defined cross-tenant relationship which defines it as trusted for Entra B2B access to be permitted.

The ability to define additional default states is being evaluated as a potential future enhancements, though it is not a high-priority item since the defined settings for default cross-tenant access establishes a default-deny stance.

**Description**:
Configures Entra B2B cross-tenant default behavior. Sets all inbound and outbound Entra B2B Collaboration and Direct Connect settings to deny all access by default unless an explicit relationship is established with a specific organization to override the default settings.

## Private Functions

### Function: Compare-CrossTenantAccessSettingDefaults

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- Current state is queried directly from Entra ID using the **Get-MgPolicyCrossTenantAccessPolicyDefault** PowerShell cmdlet.
- Desired state is assumed to be to block access by default across all possible parameters. No input is required to determine desired state.

**Properties Compared**:
- B2B Collaboration Inbound Settings
  - B2B Collaboration Inbound Access Type: Determines whether access is permitted or blocked for the users specified in the associated target group.
  - B2B Collaboration Inbound Target: Defines the groups that the type setting applies to. This is always set to all_users for the default policy.
  - B2B Collaboration Inbound Applications: These settings evaluate the list of applications the settings are configured to apply to. This defines the applications that the access type action applies to.
    - Applications Missing from Inbound Collaboration Settings: Checks for applications which are present in the desired state list but are not present in the current state list.
    - Extra Applications in the Inbound Collaboration Settings: Checks for applications which are present in the current state list but are not present in the desired state list.
- B2B Collaboration Outbound Settings
  - B2B Collaboration Outbound Access Type: Determines whether access is permitted or blocked for the users specified in the associated target group. 
  - B2B Collaboration Outbound Target: Defines the groups that the type setting applies to. This is always set to all_users for the default policy.
  - B2B Collaboration Outbound Applications
    - Applications Missing from Outbound Collaboration Settings: Checks for applications which are present in the desired state list but are not present in the current state list.
    - Extra Applications in the Outbound Collaboration Settings: Checks for applications which are present in the current state list but are not present in the desired state list.
- B2B Direct Connect Inbound Settings
  - B2B Direct Connect Inbound Access Type: Determines whether access is permitted or blocked for the users specified in the associated target group. 
  - B2B Direct Connect Inbound Target: Defines the groups that the type setting applies to. This is always set to all_users for the default policy.
  - B2B Direct Connect Inbound Applications
    - Applications Missing from Inbound Direct Connect Settings: Checks for applications which are present in the desired state list but are not present in the current state list.
    - Extra Applications in the Inbound Direct Connect Settings: Checks for applications which are present in the current state list but are not present in the desired state list.
- B2B Direct Connect Outbound Settings
  - B2B Direct Connect Outbound Access Type: Determines whether access is permitted or blocked for the users specified in the associated target group. 
  - B2B Direct Connect Outbound Target: Defines the groups that the type setting applies to. This is always set to all_users for the default policy.
  - B2B Direct Connect Outbound Applications
    - Applications Missing from Outbound Direct Connect Settings: Checks for applications which are present in the desired state list but are not present in the current state list.
    - Extra Applications in the Outbound Direct Connect Settings: Checks for applications which are present in the current state list but are not present in the desired state list.
- Is Compliant Device Accepted: Determines whether Intune device compliance signals sent from other Entra ID tenants are trusted in the tenant without having to be re-evaluated.
- Is Hybrid Azure AD Joined Device Accepted: Determines whether Intune Hybrid Device Join signals sent from other Entra ID tenants are trusted in the tenant without having to be re-evaluated.
- Is MFA Accepted: Determines whether MFA signals sent from other Entra ID tenants are trusted in the tenant without having to be re-evaluated. If this setting is set to true, Entra B2B guest users are not re-prompted for MFA when connecting to the tenant's resources if their access token indicates that they previously completed MFA, even if Conditional Access Policies would otherwise require it.

---

### Function: Compare-B2BApplicationList

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- Current state is queried directly from Entra ID using the **Get-MgPolicyCrossTenantAccessPolicyDefault** PowerShell cmdlet.
- Desired state currently assumes that the default policy should apply to "AllApplications." Additional applications may be added as part of a future enhancement.

This function is designed to be called by the **Compare-CrossTenantAccessSettingDefaults** function and is called once by each B2B cross-tenant access setting type to determine applications which should be added and removed from each setting type. It is called once by each of the following setting types.
- B2B Collaboration Inbound Settings
- B2B Collaboration Outbound Settings
- B2B Direct Connect Inbound Settings
- B2B Direct Connect Outbound Settings

It compares the current and desired application lists for each setting and returns the following two values.
- Applications Missing from Settings: Applications which are present in the desired state list but are not present in the current state list.
- Extra Applications in the Settings: Applications which are present in the current state list but are not present in the desired state list.