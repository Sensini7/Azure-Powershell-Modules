function Compare-PIMSettings {
    # Define the list of highly privileged roles with their RoleDefinitionIds
    $Roles = @(
        @{ Name = "Global Administrator"; RoleDefinitionId = "62e90394-69f5-4237-9190-012177145e10" },
        @{ Name = "Privileged Role Administrator"; RoleDefinitionId = "e8611ab8-c189-46e8-94e1-60213ab1f814" },
        @{ Name = "User Administrator"; RoleDefinitionId = "fe930be7-5e62-47db-91af-98c3a49a38b1" },
        @{ Name = "SharePoint Administrator"; RoleDefinitionId = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c" },
        @{ Name = "Exchange Administrator"; RoleDefinitionId = "29232cdf-9323-42fd-ade2-1d097af3e4de" },
        @{ Name = "Hybrid Identity Administrator"; RoleDefinitionId = "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2" },
        @{ Name = "Application Administrator"; RoleDefinitionId = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" },
        @{ Name = "Cloud Application Administrator"; RoleDefinitionId = "158c047a-c907-4556-b7ef-446551a6b5f7" }
    )

    # Retrieve the PIM_SETTINGS environment variable
    #$PIM_SETTINGS = [bool](Get-Content env:PIM_SETTINGS)

    # Initialize drift counter and summary
    $DriftCounter = 0
    $DriftSummary = @()
    $Iteration = 0

    foreach ($Role in $Roles) {
        Write-Host "===================================================================================================="
        Write-Host "Evaluating role: $($Role.Name)"
        Write-Host "===================================================================================================="

        # Get Policy Assignment
        try {
            $PolicyAssignment = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and RoleDefinitionId eq '$($Role.RoleDefinitionId)' and scopeType eq 'Directory'"
        } catch {
            Write-Host "Error retrieving policy assignment for role $($Role.Name): $_"
            $DriftSummary += "$($Role.Name) | PolicyAssignmentRetrieval | Drift Detected"
            $DriftCounter += 1
            continue
        }

        if (-Not $PolicyAssignment) {
            Write-Host "No Policy Assignment found for role $($Role.Name)"
            $DriftSummary += "$($Role.Name) | PolicyAssignmentMissing | Drift Detected"
            $DriftCounter += 1
            continue
        }

        $PolicyId = $PolicyAssignment.PolicyId

        # Get Policy Rules
        try {
            $PolicyRules = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $PolicyId
        } catch {
            Write-Host "Error retrieving policy rules for policy {$PolicyId}: $_"
            $DriftSummary += "$($Role.Name) | PolicyRulesRetrieval | Drift Detected"
            $DriftCounter += 1
            continue
        }

        foreach ($Rule in $PolicyRules) {
            switch ($Rule."@odata.type") {
                "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule" {
                    # Only Global Administrator has Approval Rule
                    if ($Role.Name -ne "Global Administrator") {
                        continue
                    }

                    $DesiredState = $PIM_SETTINGS
                    $CurrentState = $Rule.Setting.isApprovalRequired

                    Write-Host "Checking Approval Rule for role $($Role.Name)..."
                    if ($CurrentState -ne $DesiredState) {
                        Write-Host "Drift detected in Approval Rule for role $($Role.Name). Current: $CurrentState, Desired: $DesiredState"
                        $DriftSummary += "$($Role.Name) | Approval_EndUser_Assignment | Current=$CurrentState -> Desired=$DesiredState"
                        $DriftCounter += 1
                    } else {
                        Write-Host "Approval Rule for role $($Role.Name) is configured as desired."
                    }
                }
                "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule" {
                    # All roles have Notification Rules
                    # Determine which notification rule based on Rule.Id
                    switch ($Rule.Id) {
                        "Notification_Admin_Admin_Eligibility" {
                            $DesiredState = $PIM_SETTINGS
                            $CurrentState = $Rule.isDefaultRecipientsEnabled

                            Write-Host "Checking Notification_Admin_Admin_Eligibility for role $($Role.Name)..."
                            if ($CurrentState -ne $DesiredState) {
                                Write-Host "Drift detected in Notification_Admin_Admin_Eligibility for role $($Role.Name). Current: $CurrentState, Desired: $DesiredState"
                                $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Current=$CurrentState -> Desired=$DesiredState"
                                $DriftCounter += 1
                            } else {
                                Write-Host "Notification_Admin_Admin_Eligibility for role $($Role.Name) is configured as desired."
                            }
                        }
                        "Notification_Admin_Admin_Assignment" {
                            $DesiredState = $PIM_SETTINGS
                            $CurrentState = $Rule.isDefaultRecipientsEnabled

                            Write-Host "Checking Notification_Admin_Admin_Assignment for role $($Role.Name)..."
                            if ($CurrentState -ne $DesiredState) {
                                Write-Host "Drift detected in Notification_Admin_Admin_Assignment for role $($Role.Name). Current: $CurrentState, Desired: $DesiredState"
                                $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Current=$CurrentState -> Desired=$DesiredState"
                                $DriftCounter += 1
                            } else {
                                Write-Host "Notification_Admin_Admin_Assignment for role $($Role.Name) is configured as desired."
                            }
                        }
                        "Notification_Admin_EndUser_Assignment" {
                            $DesiredState = $PIM_SETTINGS
                            $CurrentState = $Rule.isDefaultRecipientsEnabled

                            Write-Host "Checking Notification_Admin_EndUser_Assignment for role $($Role.Name)..."
                            if ($CurrentState -ne $DesiredState) {
                                Write-Host "Drift detected in Notification_Admin_EndUser_Assignment for role $($Role.Name). Current: $CurrentState, Desired: $DesiredState"
                                $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Current=$CurrentState -> Desired=$DesiredState"
                                $DriftCounter += 1
                            } else {
                                Write-Host "Notification_Admin_EndUser_Assignment for role $($Role.Name) is configured as desired."
                            }
                        }
                        default {
                            Write-Host "Unknown Notification Rule: $($Rule.Id)"
                        }
                    }
                }
                default {
                    Write-Host "Unknown Rule Type: $($Rule.'@odata.type')"
                }
            }
        }
    }

    Write-Host "===================================================================================================="

    # Summarize Drift
    Write-Host "DRIFT SUMMARY:"
    if ($DriftCounter -gt 0) {
        foreach ($Drift in $DriftSummary) {
            Write-Host $Drift
        }
    } else {
        Write-Host "All PIM settings are configured as desired. No drift detected."
    }

    # Summarize Current State
    Write-Host "===================================================================================================="
    Write-Host "------------------- CURRENT STATE OF PIM SETTINGS --------------------"
    Write-Host "===================================================================================================="

    foreach ($Role in $Roles) {
        Write-Host "Role: $($Role.Name)"
        try {
            $PolicyAssignment = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and RoleDefinitionId eq '$($Role.RoleDefinitionId)' and scopeType eq 'Directory'"
            if (-Not $PolicyAssignment) {
                Write-Host "  No Policy Assignment found."
                continue
            }

            $PolicyId = $PolicyAssignment.PolicyId
            $PolicyRules = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $PolicyId

            foreach ($Rule in $PolicyRules) {
                switch ($Rule."@odata.type") {
                    "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule" {
                        Write-Host "  Rule: $($Rule.Id)"
                        Write-Host "    isApprovalRequired: $($Rule.Setting.isApprovalRequired)"
                    }
                    "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule" {
                        Write-Host "  Rule: $($Rule.Id)"
                        Write-Host "    isDefaultRecipientsEnabled: $($Rule.isDefaultRecipientsEnabled)"
                    }
                    default {
                        Write-Host "  Unknown Rule Type: $($Rule.'@odata.type')"
                    }
                }
            }
        } catch {
            Write-Host "  Error retrieving settings for role $($Role.Name): $_"
        }
    }

    Write-Host "===================================================================================================="
    if ($DriftCounter -gt 0) { 
        Write-Host "DRIFT DETECTED: CURRENT PIM SETTINGS DO NOT ALIGN WITH DESIRED CONFIGURATIONS"
    }
    else {
        Write-Host "NO DRIFT DETECTED: CURRENT PIM SETTINGS ALIGN WITH DESIRED CONFIGURATIONS"
    }
    Write-Host "===================================================================================================="

    return @{ "Iteration" = ($Iteration + 1); "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
}
