# Module: Highly Privileged Entra ID Roles PIM Settings

**Required Permissions**: The following Microsoft Graph Application permissions are required to execute this module.
- RoleManagementPolicy.ReadWrite.Directory
- RoleManagement.ReadWrite.Directory

**Required PowerShell Modules**:
- Microsoft.Graph.Identity.SignIns

**Required Featured Modules**:
- EZD.ECI.Common
- EZD.ECI.PIMSettings

## Public Functions

### Function: Set-PIMSettings

**Environment And Input Variables**:
- PIM APPROVAL REQUIRED: This is a Boolean ($true or $false) When set to true, **it sets the Global administrator role to require approval upon activation** and all other highly privileged roles including the global admin role to **Send a notification to the default recipient `admin`**

**When members are assigned as Eligible to these Roles**
**When members are assigned as Active to these Roles**
**When Eligible members Activate these roles**


- PIM ADDITIONAL NOTIFICATION RECIPIENTS: This sets the addtional emails desired to receive notification alerts along with the default recpient for all the `Highly Privileged Roles when` 

**When members are assigned as Eligible to these Roles**
**When members are assigned as Active to these Roles**
**When Eligible members Activate these roles**

It can handle both a single and mulitple Emails as an array. to not configure or set any additional email recipients at all, set this env variable to `None`. IT converts this to an empty array `@()` thereby setting the additional recipient field empty.

- The inputs for environment (`sumvita and kamvico commercial or gov`) and execution input `executechange` are passed at runtime. the execute change input defaults to false for a drift detection or dry run only.

**Description**:
Configures the Entra ID PIM Settings for highly privileged roles in compliance with `SCUBA MS.AAD.7.6,MS.AAD.7.7,MS.AAD.7.8,MS.AAD.7.9`. This ensures the global admin role requires approval upon activation, and these highly privileged roles all send notifications to both the default recipient and additional recipients when members are assigned as Eligible to these Roles, assigned as Active to these Roles and or 
when members Activate these roles. Future enhancements may expand to adjust password policy settings.

## Private Functions

### Function: Compare-PIMSettings

**Description**: Compares the current and desired state of the settings discussed above to identify drift and determine if a change is necessary to align with the desired settings.
- Current state is queried directly from Entra ID using PowerShell, utilizing the appropriate Microsoft Graph API commands.
- Desired state is specified through the PIM APPROVAL REQUIRED and PIM ADDITIONAL NOTIFICATION RECIPIENTS env variables.

  
## Usage

To use this module, ensure that you have the required permissions and PowerShell modules installed. Import the Microsoft Graph Identity SignIns module, EZD.ECI.Common and EZD.ECI.PIMSettings modules to your session. Execute the `Set-PIMSettings` function with the appropriate input variables and env variables to configure the PIM Settings for the  Entra ID Highly Privileged roles. 

- `PIM APPROVAL REQUIRED` Boolean $true or $false
- `PIM ADDITIONAL NOTIFICATION RECIPIENTS` None, for empty field and "user@easydynamics.com" for email address. For multpile emails, seperate emails with a comma (,). 
- `$IsAzureGov` ENV VARIABLE parameter indictates whether or not it is a azure commercial or azure government environment.
- `$ExecuteChange` EXECUTION INPUT. A Switch THAT determines whether or not the function runs in Drift Detection (dry run) only mode or Deployment mode (detects and executes changes in case of a drift)

e.g 
Set-PIMSettings -ExecuteChange $true -PIM_APPROVAL_REQUIRED $true -PIM ADDITIONAL NOTIFICATION RECIPIENTS "user@easydynamics.com" 
- `Set-PasswordPolicy -PASSWORD_EXPIRATION_PERIOD 0  -ExecuteChange true` deployment run to set global admin role to require approval upon activation, and all highly privileged roles to send notifications to default recipient the addtional recipient user@easydynamics.com 

**When members are assigned as Eligible to these Roles**
**When members are assigned as Active to these Roles**
**When Eligible members Activate these roles**


     

## Future Enhancements
- Integration with other security and identity management features in Entra ID.