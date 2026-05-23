# Module: System Use Notification

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- OrganizationalBranding.ReadWrite.All

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns
- Microsoft.Graph.Identity.DirectoryManagement

## Public Functions

### Function: Set-SignInText

**Setting Location**: Entra Admin Center > User Experiences > Company Branding > Default Sign-In - Sign-In Page Text

**Input Variables**:
- AZURE_TENANT_ID: The ID of the Entra ID tenant being configured.
- SIGN_IN_TEXT: The desired sign-in text to be displayed upon sign-in to the Entra ID tenant.

**Description**:
Updates the notification which appears at the footer of the Entra ID sign-in page.

## Private Functions

### Function: Compare-SignInText

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- Current state is queried directly from Entra ID using PowerShell, using the **(Get-MgOrganizationBranding -OrganizationId $TenantId).SignInPageText** cmdlet. 
- Desired state is based upon the secrets which are populated in the key vault specified in the SIGN_IN_TEXT variable.

**Properties Compared**:
- SIGN_IN_TEXT