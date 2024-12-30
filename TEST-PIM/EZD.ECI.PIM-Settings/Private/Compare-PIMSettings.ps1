function Compare-PIMSettings {
    # Define your roles with their RoleDefinitionIds
    $Roles = @(
        @{ Name = "Global Administrator";             RoleDefinitionId = "62e90394-69f5-4237-9190-012177145e10" },
        @{ Name = "Privileged Role Administrator";    RoleDefinitionId = "e8611ab8-c189-46e8-94e1-60213ab1f814" },
        @{ Name = "User Administrator";               RoleDefinitionId = "fe930be7-5e62-47db-91af-98c3a49a38b1" },
        @{ Name = "SharePoint Administrator";         RoleDefinitionId = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c" },
        @{ Name = "Exchange Administrator";           RoleDefinitionId = "29232cdf-9323-42fd-ade2-1d097af3e4de" },
        @{ Name = "Hybrid Identity Administrator";    RoleDefinitionId = "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2" },
        @{ Name = "Application Administrator";        RoleDefinitionId = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" },
        @{ Name = "Cloud Application Administrator";  RoleDefinitionId = "158c047a-c907-4556-b7ef-446551a6b5f7" }
    )

    # We'll read the PIM_SETTINGS from an environment variable or from a parameter, 
    # but if it's environment-based, do something like this:
    # $PIM_SETTINGS = [bool]$env:PIM_SETTINGS
    #
    # If you want to pass it from the public function, you could do so via 
    # param or other means. For now, let's assume it's in env:
    #$PIM_SETTINGS = [bool]$env:PIM_SETTINGS

    # Initialize counters
    $DriftCounter = 0
    $DriftSummary = @()
    $Iteration    = 0

    # Compile the current state
    foreach ($Role in $Roles) {
        Write-Host "===================================================================================================="
        Write-Host "Evaluating role: $($Role.Name)"
        Write-Host "===================================================================================================="

        # 1. Get the policy assignment for this role
        try {
            $PolicyAssignment = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and RoleDefinitionId eq '$($Role.RoleDefinitionId)' and scopeType eq 'Directory'"
        } catch {
            Write-Host "Error retrieving policy assignment for role $($Role.Name): $_"
            continue
        }

        if (-not $PolicyAssignment) {
            Write-Host "No Policy Assignment found for role $($Role.Name). Skipping."
            continue
        }

        $PolicyId = $PolicyAssignment.PolicyId

        # 2. Get the policy rules for that assignment
        try {
            $PolicyRules = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $PolicyId
        } catch {
            Write-Host "Error retrieving policy rules for policy {$PolicyId}: $_"
            continue
        }


        # Calculate the drift of the current state from the desired state
        # 3. Compare only the 4 specific rule IDs you care about
        foreach ($Rule in $PolicyRules) {
            
            switch ($Rule.Id) {
                # 1) Approval Rule for GA requires approval
                "Approval_EndUser_Assignment" {

                    if ($Role.Name -ne "Global Administrator") {
                        # Skip evaluating Approval rule for non-Global Admin roles
                        continue
                    }
                    # Check if it's an approval rule
                    # Usually => '@odata.type' = '#microsoft.graph.unifiedRoleManagementPolicyApprovalRule'
                    # Settings => AdditionalProperties.Settings / or .Setting (depending on the Graph module)
                    # Example comparison:
                    $CurrentIsApprovalRequired = $Rule.AdditionalProperties.setting.isApprovalRequired
                    $DesiredIsApprovalRequired = $PIM_SETTINGS

                    if ($CurrentIsApprovalRequired -ne $DesiredIsApprovalRequired) {
                        Write-Host "Drift in Approval_EndUser_Assignment for role $($Role.Name)."
                        Write-Host "  Current: $CurrentIsApprovalRequired, Desired: $DesiredIsApprovalRequired"
                        $DriftSummary += "$($Role.Name) | Approval_EndUser_Assignment | Current=$CurrentIsApprovalRequired -> Desired=$DesiredIsApprovalRequired"
                        $DriftCounter += 1
                    } else {
                        Write-Host "Approval rule for role $($Role.Name) is as desired."
                    }
                }

                # 2) Notification_Admin_EndUser_Assignment
                "Notification_Admin_EndUser_Assignment" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled
                    $DesiredIsDefaultRecipientsEnabled = $PIM_SETTINGS

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled) {
                        Write-Host "Drift in Notification_Admin_EndUser_Assignment for role $($Role.Name)."
                        Write-Host "  Current: $CurrentIsDefaultRecipientsEnabled, Desired: $DesiredIsDefaultRecipientsEnabled"
                        $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Current=$CurrentIsDefaultRecipientsEnabled -> Desired=$DesiredIsDefaultRecipientsEnabled"
                        $DriftCounter += 1
                    } else {
                        Write-Host "Notification_Admin_EndUser_Assignment rule for role $($Role.Name) is as desired."
                    }
                }

                # 3) Notification_Admin_Admin_Eligibility
                "Notification_Admin_Admin_Eligibility" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled
                    $DesiredIsDefaultRecipientsEnabled = $PIM_SETTINGS

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled) {
                        Write-Host "Drift in Notification_Admin_Admin_Eligibility for role $($Role.Name)."
                        Write-Host "  Current: $CurrentIsDefaultRecipientsEnabled, Desired: $DesiredIsDefaultRecipientsEnabled"
                        $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Current=$CurrentIsDefaultRecipientsEnabled -> Desired=$DesiredIsDefaultRecipientsEnabled"
                        $DriftCounter += 1
                    } else {
                        Write-Host "Notification_Admin_Admin_Eligibility rule for role $($Role.Name) is as desired."
                    }
                }

                # 4) Notification_Admin_Admin_Assignment
                "Notification_Admin_Admin_Assignment" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled
                    $DesiredIsDefaultRecipientsEnabled = $PIM_SETTINGS

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled) {
                        Write-Host "Drift in Notification_Admin_Admin_Assignment for role $($Role.Name)."
                        Write-Host "  Current: $CurrentIsDefaultRecipientsEnabled, Desired: $DesiredIsDefaultRecipientsEnabled"
                        $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Current=$CurrentIsDefaultRecipientsEnabled -> Desired=$DesiredIsDefaultRecipientsEnabled"
                        $DriftCounter += 1
                    } else {
                        Write-Host "Notification_Admin_Admin_Assignment rule for role $($Role.Name) is as desired."
                    }
                }

                # Unknown or not relevant => skip
                default {
                    continue
                }
            }
        }
    }

    Write-Host "===================================================================================================="
    # Summarize drift
    #$DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if ($DriftCounter -gt 0) {
        $DriftSummary | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "All PIM settings for these 4 rules are configured as desired. No drift detected."
    }

    # Return the results
    return @{
        "Iteration"     = ($Iteration + 1)
        "DriftCounter"  = $DriftCounter
        "DriftSummary"  = $DriftSummary
    }
}
