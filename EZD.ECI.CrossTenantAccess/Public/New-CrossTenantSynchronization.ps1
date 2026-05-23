# Allows partners to access resources across different tenants. 
# It constructs a new policy object and associates it with a partner’s service principal. 
# Useful for managing access rights of external partners 
# to resources within an organization’s Microsoft 365 tenant.
# Can configure inbound or outbound access settings for 
# cross-tenant synchronization. 

function New-CrossTenantSynchronization {
    param ( 
        [Parameter (Mandatory = $true)]
        [string] $TargetTenants,

        [Parameter (Mandatory = $true)]
        [ValidateSet ("inbound", "outbound")]
        [string] $Direction,

        # Flag that specifies whether or not to block access to all applications
        [switch] $BlockAll,

        # Represents list of allowed applications for inbound and outbound access policy
        # Can be one of the following values: 
        # The unique identifier of the user, group, or application 
        # AllUsers 
        # AllApplications - Refers to any Microsoft cloud application. 
        # Office365 - Includes the applications mentioned as part of the Office365 suite.
        #
        # INPUT MUST BE COMMA SEPARATED WITH NO SPACES
        [string] $AllowedApps = ""
    )

    if ($AllowedApps -and $BlockAll) {
        Write-Output $BlockAll       
        throw "Please only specify one: block access to all applications OR input preferred applications."
    }
    $ApplicationList = $AllowedApps.Split(",")

    # Sign in to the management tenant and consent to required permissions
    if (-Not (Get-MgContext)) {
        throw "Please sign in to the management tenant first. Run Connect-MgGraph to sign in."
    }

    # Sets the appropriate values according to whether the configuration is inbound or outbound
    switch ($Direction) {
        "inbound" {
            $DirectionParam = "B2BCollaborationInbound"
        }
        "outbound" {
            $DirectionParam = "B2BCollaborationOutbound"
        }
    }

    # If no apps are specified, deny access to all apps
    # Otherwise, if user inputs an application, allow access to only explicitly mentioned apps
    if ($BlockAll -or (-not $ApplicationList[0])){
        if (-not $BlockAll) {
            Write-Error "BlockAll flag is false but no applications were specified. Please inputs preferred apps."
        }
        
        # Blocking all users also blocks all external applications
        # Access type must be same for users and groups as well as external applications
        $UserParam = @{
            AccessType = "blocked"
            Targets = @(
                @{
                    Target = "AllUsers"
                    TargetType = "user"
                }
            )
        }
        $AppParam = @{}

    } else {
        # Array of hastables that includes key value pairs of each application to be included in the allow list
        $ApplicationTargets = @()
        foreach ($App in $ApplicationList){
            $ApplicationTargets += @{
                Target = $App
                TargetType = "application"
            }
        }

        $AppParam = @{
            AccessType = "allowed"
            Targets = $ApplicationTargets
        }
        
        $UserParam = @{
            AccessType = "allowed"
            Targets = @(
                @{
                    Target = "AllUsers"
                    TargetType = "user"
                }
            )
        }
    }

    # Ensures that target tenants are held in an array format.
    [String[]] $TargetTenantArr = $TargetTenants.Split(",")
    Write-Host "The Listed Target Tenants are $TargetTenantArr"

    # Creates or updates (if one already exists) cross tenant settings for each target tenant. 
    foreach ($Target in $TargetTenantArr){
        # Check if an organizational relationship exists between resource and management tenant. 
        $OrgInfo = Get-MgPolicyCrossTenantAccessPolicyPartner | Where-Object { $_.TenantId -eq $Target }

        # Sets parameters of the new cross-tenant access policy 
        $BodyParams = @{
            BodyParameter = @{
                TenantId = $Target
                $DirectionParam = @{
                    UsersAndGroups = $UserParam
                    Applications = $AppParam
                }
            }
        }

        # If no preexisting relationship exists between the two tenant, create one
        # Else, update the configurations of the current relationship
        if (-not ($OrgInfo)){
            Write-Output "No Cross Tenant Access Policy Partners found, creating a new one with the following parameters:"
            $BodyParams.BodyParameter | ConvertTo-Json -Depth 30
            $HideOutput = New-MgPolicyCrossTenantAccessPolicyPartner @BodyParams
        } else {
            Write-Output "Existing Cross Tenant Access Policy Partners:"
            $BodyParams.BodyParameter | ConvertTo-Json -Depth 30

            $IsSame = $true
            # Compare inputs with current access policy settings to detect any drift
            $CurrentApps = Get-MgPolicyCrossTenantAccessPolicyPartner | 
                        Where-Object { $_.TenantId -eq $Target } |
                        Select-Object -ExpandProperty $DirectionParam |
                        Select-Object -ExpandProperty Applications |
                        Select-Object -ExpandProperty Targets

            if ($CurrentApps.Length -eq $ApplicationList.Length) {
                foreach ($App in $ApplicationList) {
                    $AppExists = Get-MgPolicyCrossTenantAccessPolicyPartner | 
                                Where-Object { $_.TenantId -eq $Target } |
                                Select-Object -ExpandProperty $DirectionParam |
                                Select-Object -ExpandProperty Applications |
                                Select-Object -ExpandProperty Targets |
                                Where-Object {$_.Target -eq $App }
        
                    # If an input application is not listed in the current policy, drift is detected
                    if (-not ($AppExists)) {
                        $IsSame = $false
                    }
                }
            } else {
                $IsSame = $false
            }

            if (-not ($IsSame)) {
                $HideOutput = Update-MgPolicyCrossTenantAccessPolicyPartner -CrossTenantAccessPolicyConfigurationPartnerTenantId $Target @BodyParams
            }
        }
    }
    
}
