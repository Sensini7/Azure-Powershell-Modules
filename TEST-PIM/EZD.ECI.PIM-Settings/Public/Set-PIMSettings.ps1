function Set-PIMSettings {
    param (
        [bool]$PIM_SETTINGS,
        [bool]$ExecuteChange
    )

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

    # Define the desired password validity period in the parent scope
    $DesiredState = $PIM_SETTINGS

    Write-Host "===================================================================================================="
    if (-Not ($ExecuteChange)) {
        Write-Host "Current: Drift Detection Run"
    } else {
        Write-Host "Current: Deployment Run"
    }
    Write-Host "===================================================================================================="

    Write-Host "Compiling current state and calculating drift..."
    $PreResults = Compare-PIMSettings
    $Iteration = $PreResults["Iteration"]
    $DriftCounter = $PreResults["DriftCounter"]
    $DriftSummary = $PreResults["DriftSummary"]

    if (-Not ($ExecuteChange)) {
        Write-Host "THIS IS A DRIFT DETECTION RUN. NO CHANGES WILL BE MADE"
        if ($DriftCounter -gt 0) {
            return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
        } else {
            return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
        }
    } else {
        if ($DriftCounter -gt 0) {
            Write-Host "UPDATING PIM SETTINGS TO MATCH THE DESIRED STATE."
            foreach ($Drift in $DriftSummary) {
                # Extract RoleName and RuleId from Drift summary entry
                # Expected format: "RoleName | RuleId | CurrentState -> DesiredState"
                $Parts = $Drift -split '\|'
                if ($Parts.Count -lt 3) {
                    Write-Host "Invalid DriftSummary format: $Drift"
                    continue
                }

                $RoleName = $Parts[0].Trim()
                $RuleId = $Parts[1].Trim()
                $DesiredState = $Parts[2].Trim()

                # Find the RoleDefinitionId based on RoleName
                $Role = $Roles | Where-Object { $_.Name -eq $RoleName }
                if (-Not $Role) {
                    Write-Host "Role not found: $RoleName"
                    continue
                }

                # Get Policy Assignment
                try {
                    $PolicyAssignment = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and RoleDefinitionId eq '$($Role.RoleDefinitionId)' and scopeType eq 'Directory'"
                } catch {
                    Write-Host "Error retrieving policy assignment for role {$RoleName}: $_"
                    continue
                }

                if (-Not $PolicyAssignment) {
                    Write-Host "No Policy Assignment found for role $RoleName"
                    continue
                }

                $PolicyId = $PolicyAssignment.PolicyId

                # Get Policy Rules
                try {
                    $PolicyRules = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $PolicyId
                } catch {
                    Write-Host "Error retrieving policy rules for policy {$PolicyId}: $_"
                    continue
                }

                # Find the specific rule
                $Rule = $PolicyRules | Where-Object { $_.Id -eq $RuleId }
                if (-Not $Rule) {
                    Write-Host "Rule $RuleId not found for policy $PolicyId"
                    continue
                }

                # Define @params based on Rule type and desired state
                switch ($Rule."@odata.type") {
                    "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule" {
                        $params = @{
                            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"
                            id = $Rule.Id
                            target = $Rule.Target
                            setting = @{
                                "@odata.type" = "#microsoft.graph.approvalSettings"
                                isApprovalRequired = [bool]$DesiredState.Split('=')[-1].Trim()
                                approvalStages = @()
                            }
                        }
                    }
                    "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule" {
                        $params = @{
                            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                            id = $Rule.Id
                            target = $Rule.Target
                            notificationType = $Rule.NotificationType
                            recipientType = $Rule.RecipientType
                            notificationLevel = $Rule.NotificationLevel
                            isDefaultRecipientsEnabled = [bool]$DesiredState.Split('=')[-1].Trim()
                            notificationRecipients = $Rule.NotificationRecipients
                        }
                    }
                    default {
                        Write-Host "Unknown rule type: $($Rule.'@odata.type')"
                        continue
                    }
                }

                # Update the policy rule
                try {
                    Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $PolicyId -UnifiedRoleManagementPolicyRuleId $Rule.Id -BodyParameter $params
                    Write-Host "Successfully updated rule $RuleId for role $RoleName."
                } catch {
                    Write-Host "Error updating rule $RuleId for role {$RoleName}: $_"
                }
            }

            Write-Host "===================================================================================================="
            Write-Host "Performing post-configuration drift detection."
            Write-Host "===================================================================================================="

            $PostResults = Compare-PIMSettings
            $DriftCounter = $PostResults["DriftCounter"]
            $DriftSummary = $PostResults["DriftSummary"]

            if ($DriftCounter -eq 0) {
                Write-Host "PIM SETTINGS ARE CONFIGURED AS DESIRED. THE CHANGE WAS SUCCESSFUL."
                return Get-ReturnValue -ExitCode 3 -DriftSummary $DriftSummary
            } else {
                Write-Host "WARNING: SETTINGS DID NOT PASS POST-EXECUTION CHECKS. THE CHANGE WAS NOT SUCCESSFUL"
                return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
            }
        } elseif ($DriftCounter -eq 0) {
            Write-Host "NO CHANGE IS REQUIRED. SETTINGS ARE ALREADY CONFIGURED AS DESIRED."
            return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
        } else {
            Write-Host "WARNING: UNABLE TO COMPLETE POST-EXECUTION VALIDATION."
            return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
        }
    }
}
