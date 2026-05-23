# Module: Directory Settings

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Group.ReadWrite.All
- Policy.ReadWrite.AuthenticationMethod
- Directory.ReadWrite.All

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns
- Microsoft.Graph.Beta.Identity.DirectoryManagement
- Microsoft.Graph.Groups

## Public Functions

### Function: Set-GroupCreatorsGroup

**Setting Location in Azure Portal**: Can only be configured via PowerShell.

**Input Variables**:
- ENABLE_GROUP_CREATION_FOR_ALL_USERS: Determines whether a user must be a member of a Microsoft 365 Group Creation Group or a tenant-level administrator role to create new Microsoft 365 Groups. Boolean.

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Group.ReadWrite.All
- Policy.ReadWrite.AuthenticationMethod
- Directory.ReadWrite.All

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns
- Microsoft.Graph.Beta.Identity.DirectoryManagement
- Microsoft.Graph.Groups

**Description**:
Updates the Entra ID Group Creation Group restriction settings. These determine whether standard users are permitted to create Microsoft 365 Groups, or whether they either must be members of a group which is permitted to create groups or hold a tenant-level administrator role which permits them to do so.

---

### Function: Update-PasswordProtection

**Setting Location in Azure Portal**: Entra ID > Security > Authentication Methods > Password Protection

**Input Variables**:
- BANNED_PASSWORD_CHECK_ONPREM_MODE: Determines if synced passwords are evaluated against the banned password list. String.
- BANNED_PASSWORD_LIST: Determines the the list of words included in the banned password list. Collection.
- ENABLE_BANNED_PASSWORD_CHECK: Determines if cloud-only passwords are evaluated against the banned password list. Boolean.
- ENABLE_BANNED_PASSWORD_CHECK_ONPREM: Determines if synced passwords are evaluated against the banned password list. Boolean.
- LOCKOUT_DURATION_IN_SECONDS: Determines the initial lockout duration if a lockout is triggered. Integer.
- LOCKOUT_THRESHOLD: Determines the number of unsuccessful lockout attempts needed to trigger an account lockout. Integer.

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.AuthenticationMethod
- Directory.ReadWrite.All

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns
- Microsoft.Graph.Beta.Identity.DirectoryManagement

**Description**:
Configures the Entra ID password protection policy for the tenant. This includes password-specific settings, such as banned password list, as well as related settings such as smart lockout threshold and duration.

## Private Functions

### Function: Compare-GroupCreatorsGroup

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- Current state is queried directly from Entra ID using PowerShell, using the **(Get-MgBetaDirectorySetting | Where-Object { $_.DisplayName -eq "Password Rule Settings" }).Values** cmdlet. 
- Desired state is based upon the values of the ENABLE_GROUP_CREATION_FOR_ALL_USERS variable. Additional inputs, such as whether the Group Creation Group already exists and the Group Creation Group ID, are queried directly from Entra ID using the **(Get-MgGroup -Filter "DisplayName eq '$GroupCreationGroupName'").Id** cmdlet.

**Properties Compared**:
- ENABLE_GROUP_CREATION_FOR_ALL_USERS: Checks if membership in a group creation group is required to create Microsoft 365 Groups in the desired settings.
- Directory Setting Object for Group Creation Group Settings Exists: Checks if the directory settings object which specifies the desired Group Creation Group setting and the object ID of the Group Creation Group exists.
- Group Creation Group Exists: Checks if the Group Creation Group currently exists or if it needs to be created.
- Group Creation Group set to Correct Group: Checks that the Group Creation Group requirement is set to target membership in the correct Entra ID group.

---

### Function: Compare-PasswordProtection

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- All current state parameters are passed to this function from its parent Public function and retrieved using the **(Get-MgPolicyAuthorizationPolicy).DefaultUserRolePermissions.PermissionGrantPoliciesAssigned** cmdlet.
- Desired state is based upon the values of the following variables.
  - BANNED_PASSWORD_CHECK_ONPREM_MODE
  - BANNED_PASSWORD_LIST
  - ENABLE_BANNED_PASSWORD_CHECK
  - ENABLE_BANNED_PASSWORD_CHECK_ONPREM
  - LOCKOUT_DURATION_IN_SECONDS
  - LOCKOUT_THRESHOLD

**Properties Compared**:
- Directory Setting Object for Password Protection Exists: Checks if the directory settings object which specifies the desired password protection settings exists.
- BANNED_PASSWORD_CHECK_ONPREM_MODE
- BANNED_PASSWORD_LIST
  - Passwords Missing from Banned Password List: Checks if there are any objects in the desired state banned password list which are not in the current state banned password list.
  - Extra Passwords in the Banned Password List: Checks if there are any objects in the current state banned password list which are not in the desired state banned password list.
- ENABLE_BANNED_PASSWORD_CHECK
- ENABLE_BANNED_PASSWORD_CHECK_ONPREM
- LOCKOUT_DURATION_IN_SECONDS
- LOCKOUT_THRESHOLD

---

### Function: New-GroupCreatorsGroup

**Description**: Evaluates whether a Microsoft 365 Group Creators Group already exists in the tenant using an exact-match query by Display Name. Designed to be called by the **Compare-GroupCreatorsGroup** function.

If the group exists, it passes the object ID of the group back to the parent Compare function which called it. If the group does not exist, it creates the group and then passes the object ID of the newly created group back to the Compare function which called it.

It retrieves the object ID of the Microsoft 365 Group Creators Group by calling the private function **Get-GroupCreatorsGroup**, which is defined internally within the same PowerShell file.

---

### Function: Get-GroupCreatorsGroup

**Description**: Retrieves the object ID of the Microsoft 365 Group Creators Group. If an existing Microsoft 365 Group Creators Group is found, it returns the object ID of the group and produces a line in the execution logs which indicate that a group was found. If an existing Microsoft 365 Group Creators Group is not found, it indicates that a group was not found in the execution logs and returns a null value.

This function is designed to be executed as a pre- and post-execution check within the **New-GroupCreatorsGroup** function, and is defined within the same file. It behaves similarly to a Compare function, with its output determining whether the New-GroupCreatorsGroup function performs a change to deploy a new Microsoft 365 Group Creators Group or makes no change and instead returns the object ID of the existing group.