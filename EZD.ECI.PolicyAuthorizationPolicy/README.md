# Module: Authorization Policy

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.Authorization

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

## Public Functions

### Function: Set-DefaultUserRolePermissions

**Setting Location in Azure Portal**: Entra ID > User Settings > Default User Role Permissions

**Input Variables**:
- ALLOW_NONPRIV_SECURITY_GROUP_CREATION: Determines whether standard users (users who do not hold a tenant-level admin role) are permitted to create cloud-only security groups. Boolean.
- ALLOW_NONPRIV_B2C_TENANT_CREATION: Determines whether standard users (users who do not hold a tenant-level admin role) are permitted to create Entra B2C tenants. Boolean.
- ALLOW_NONPRIV_ENTERPRISE_APP_CREATION: Determines whether standard users (users who do not hold a tenant-level admin role) are permitted to create Entra ID App Registrations. Boolean.

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.Authorization

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Updates default user role permissions in Entra ID. These control the actions that standard users (users who do not hold a tenant-level admin role) are permitted to perform in Entra ID.

---

### Function: Set-EnterpriseAppUserConsentSetting

**Setting Location in Azure Portal**: Entra ID > Enterprise Applications > Consent and Permissions

**Input Variables**:
- ENT_APP_DEFAULT_CONSENT_PERMISSIONS: Determines whether users are permitted to consent to all applications, a subset of applications or no applications. String.

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.Authorization

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

**Description**:
Configures the tenant Enterprise App Consent policy. Policy can be set to disallow user consent to all applications, to allow consent only to specific applications or to allow user consent to all applications.

## Private Functions

### Function: Compare-DefaultUserRolePermissions

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- Current state is queried directly from Entra ID using PowerShell, using the **(Get-MgPolicyAuthorizationPolicy).DefaultUserRolePermissions** cmdlet. 
- Desired state is based upon the values of the following variables.
  - ALLOW_NONPRIV_SECURITY_GROUP_CREATION
  - ALLOW_NONPRIV_B2C_TENANT_CREATION
  - ALLOW_NONPRIV_ENTERPRISE_APP_CREATION

**Properties Compared**:
- ALLOW_NONPRIV_SECURITY_GROUP_CREATION
- ALLOW_NONPRIV_B2C_TENANT_CREATION
- ALLOW_NONPRIV_ENTERPRISE_APP_CREATION

---

### Function: Compare-EnterpriseAppUserConsentSetting

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **(Get-MgPolicyAuthorizationPolicy).DefaultUserRolePermissions.PermissionGrantPoliciesAssigned** cmdlet.
- Desired state is based upon the value of the ENT_APP_DEFAULT_CONSENT_PERMISSIONS variable.

**Properties Compared**:
- ENT_APP_DEFAULT_CONSENT_PERMISSIONS