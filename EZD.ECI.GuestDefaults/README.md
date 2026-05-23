# Module: External Collaboration Settings

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.Read.All
- Policy.ReadWrite.AuthenticationFlows
- Policy.ReadWrite.Authorization
- Policy.ReadWrite.ExternalIdentities

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns
- Microsoft.Graph.Beta.Identity.SignIns

## Public Functions

### Function: Set-GuestDefaults

**Setting Location**: Azure Portal > Entra ID > External Identities > External Collaboration Settings

**Input Variables**:
- GUEST_USER_ROLE_ID: The GUID of the permissions role assigned to Entra B2B guest users. Determines the level of access an Entra B2B guest user has by default. String.
- GUEST_INVITER_RESTRICTIONS: Determines which users are permitted to invite Entra B2B guest users into the tenant (all users, only internal users, users with an admin role and no users). String.
- ALLOW_GUEST_SELF_SERVICE_SIGNUP: Determines whether Entra B2B guest self-service sign-up is enabled in the tenant. Boolean.
- ALLOW_GUEST_SELF_SERVICE_LEAVE: Determines whether Entra B2B guest users are permitted to leave the organization without intervention by a tenant admin. Boolean.

**Description**:
Updates Entra B2B external collaboration settings. These settings determine the behavior of default security controls which apply to all Entra B2B users present in the tenant.

## Private Functions

### Function: Compare-GuestDefaults

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- Current state is queried directly from Entra ID using PowerShell, using the following cmdlets:
  - Guest User Role ID and Guest Inviter Restrictions: Get-MgPolicyAuthorizationPolicy
  - Allow Guest Self Service Signup: (Get-MgBetaPolicyAuthenticationFlowPolicy).SelfServiceSignUp.IsEnabled
  - Allow Guest Self Service Leave: Get-MgBetaPolicyExternalIdentityPolicy
- Desired state is based upon the secrets which are populated in the key vault specified in the following variables.
  - GUEST_USER_ROLE_ID
  - GUEST_INVITER_RESTRICTIONS
  - ALLOW_GUEST_SELF_SERVICE_SIGNUP
  - ALLOW_GUEST_SELF_SERVICE_LEAVE
**Properties Compared**:
- GUEST_USER_ROLE_ID
- GUEST_INVITER_RESTRICTIONS
- ALLOW_GUEST_SELF_SERVICE_SIGNUP
- ALLOW_GUEST_SELF_SERVICE_LEAVE