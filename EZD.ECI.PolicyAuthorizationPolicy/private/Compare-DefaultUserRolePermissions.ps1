function Compare-DefaultUserPermissions {

    # Compile current state
    $CurrentDefaultUserRolePermissions = (Get-MgPolicyAuthorizationPolicy).DefaultUserRolePermissions

    # Loop through user role permissions to detect drift
    $DriftCounter = 0
    foreach($Permission in $DefaultUserRolePermissions.Keys)
    {
        # Set the variables for the current role
        $UserRolePermissionName = $Permission
        $UserRolePermissionIsAllowed = $DefaultUserRolePermissions[$Permission]

        # Compile the current state of the setting
        $CurrentAllowedUserRolePermission = $CurrentDefaultUserRolePermissions.$UserRolePermissionName

        # Calculate drift of the current state from the desired state
        if ($CurrentAllowedUserRolePermission -ne $UserRolePermissionIsAllowed) 
        {
            Write-Host "Default permission $UserRolePermissionName does not align with the desired state. It should be set to: $UserRolePermissionIsAllowed"
            $DriftCounter += 1
        }
        elseif ($CurrentAllowedUserRolePermission -eq $UserRolePermissionIsAllowed) 
        {
            Write-Host "Default permission $UserRolePermissionName aligns with the desired state ($UserRolePermissionIsAllowed). No change is necessary."
        }
        else 
        {
            Write-Host "WARNING: Configuration for default permission $UserRolePermissionName could not be retrieved."
            $ReturnCode = 1
        }
    }

    Write-Host "----------------------------------------------------------------------------------------------------"

    ### Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        foreach($Permission in $DefaultUserRolePermissions.Keys)
        {
            # Set the variables for the current role
            $UserRolePermissionName = $Permission
            $UserRolePermissionIsAllowed = $DefaultUserRolePermissions[$Permission]

            # Gather current state
            $CurrentAllowedUserRolePermission = $CurrentDefaultUserRolePermissions.$UserRolePermissionName

            # Capture drift summary
            if ($CurrentAllowedUserRolePermission -ne $UserRolePermissionIsAllowed) 
            {
                $DriftSummary += Write-Output "CURRENT: $UserRolePermissionName setting is $CurrentAllowedUserRolePermission -> DESIRED: Setting should be set to $UserRolePermissionIsAllowed"
            }
        }
    }
    else
    {
        $DriftSummary += Write-Output "No drift detected. The current state aligns with the desired state."
    }

    $DriftSummary | foreach { Write-Host $_}

    Write-Host "===================================================================================================="
  
    # Summarize current state
    if($Iteration -gt 0) {
        Write-Host "------------------ Current State of Default User Role Permissions After Changes -------------------"
    }
    else {
        Write-Host "------------------ Current State of Default User Role Permissions Before Changes ------------------"
    }
    foreach($Permission in $DefaultUserRolePermissions.Keys)
    {
        # Set the variables for the current role
        $UserRolePermissionName = $Permission
        $UserRolePermissionIsAllowed = $DefaultUserRolePermissions[$Permission]
        Write-Host "$UserRolePermissionName`: $($CurrentDefaultUserRolePermissions.$UserRolePermissionName)"
    }

    $Iteration += 1

    Write-Host "===================================================================================================="
    if($DriftCounter -gt 0)
    {
        Write-Host "DRIFT DETECTED: The current state does not align with the desired state."
    }
    else
    {
        Write-Host "NO DRIFT DETECTED: The current state aligns with the desired state."
    }
    Write-Host "===================================================================================================="

    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "ReturnCode" = $ReturnCode; "DriftSummary" = $DriftSummary }

}