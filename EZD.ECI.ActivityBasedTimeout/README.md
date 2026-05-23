# Module: Activity Based Timeout

**Required Permissions**: The following Microsoft Graph permissions are required to execute this module.
- Policy.ReadWrite.ApplicationConfiguration

**Required PowerShell Modules**:
- EZD.ECI.Common
- Microsoft.Graph.Identity.SignIns

## Public Functions

### Function: Set-ActivityBasedTimeoutPolicy

**Setting Location in Azure Portal**: Settings > Signing out + notifications

**Input Variables**:
- AZURE_WEB_SESSION_IDLE_TIMEOUT: The desired inactivity timeout period for the sessions in the Azure Portal.

**Description**:
Updates the inactivity timeout period for native Microsoft applications. Currently, the function only supports configuration of the Azure Portal inactivity timeout period. Future enhancements will be added for the tenant-wide application timeout period and other specific applications.

## Private Functions

### Function: Compare-ActivityBasedTimeoutPolicy

**Description**: Compares current and desired state of the associated Public Function to calculate drift and determine if a change is necessary to bring the setting into alignment with desired settings.
- Current state is queried directly from Entra ID using PowerShell, using the **Get-MgPolicyActivityBasedTimeoutPolicy | Where {$_.displayName -eq "ActivityBasedTimeoutPolicy"}** cmdlet. 
- Desired state is based upon the secrets which are populated in the key vault specified in the AZURE_WEB_SESSION_IDLE_TIMEOUT variable.

**Properties Compared**:
- AZURE_WEB_SESSION_IDLE_TIMEOUT
  - Timeout Periods to be Added: Applications without an idle timeout period configured in the current state which have an idle timeout configured in the desired state.
  - Timeout Periods to be Modified: Applications with an idle timeout period configured in the current state which does not align with the desired idle timeout in the desired state.
  - Timeout Periods to be Removed: Applications with an idle timeout configured in the current state which do not have an idle timeout configured in the desired state.