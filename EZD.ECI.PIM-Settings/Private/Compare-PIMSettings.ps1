function Compare-PIMSettings {
    # Define your roles with their RoleDefinitionIds
    # $Roles = @(
    #     @{ Name = "Global Administrator";             RoleDefinitionId = "62e90394-69f5-4237-9190-012177145e10" },
    #     @{ Name = "Privileged Role Administrator";    RoleDefinitionId = "e8611ab8-c189-46e8-94e1-60213ab1f814" },
    #     @{ Name = "User Administrator";               RoleDefinitionId = "fe930be7-5e62-47db-91af-98c3a49a38b1" },
    #     @{ Name = "SharePoint Administrator";         RoleDefinitionId = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c" },
    #     @{ Name = "Exchange Administrator";           RoleDefinitionId = "29232cdf-9323-42fd-ade2-1d097af3e4de" },
    #     @{ Name = "Hybrid Identity Administrator";    RoleDefinitionId = "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2" },
    #     @{ Name = "Application Administrator";        RoleDefinitionId = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" },
    #     @{ Name = "Cloud Application Administrator";  RoleDefinitionId = "158c047a-c907-4556-b7ef-446551a6b5f7" }
    # )
    
    #$AllPolicyRules = @{}  # To store rules for all roles

    # We'll read the PIM_SETTINGS from an environment variable or from a parameter, 
    # but if it's environment-based, do something like this:
    # $PIM_SETTINGS = [bool]$env:PIM_SETTINGS
    #
    # If you want to pass it from the public function, you could do so via 
    # param or other means. For now, let's assume it's in env:
    #$PIM_SETTINGS = [bool]$env:PIM_SETTINGS
    #$AllPolicyRules[$Role.Name] = $PolicyRules
    # Initialize counters
    $DriftCounter = 0
    #$DriftSummary = @()
    #$Iteration    = 0

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

        $AllPolicyRules[$Role.Name] = $PolicyRules


        # Calculate the drift of the current state from the desired state
        # 3. Compare only the 4 specific rule IDs you care about
        #$DriftCounter = 0
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

                    $DesiredIsApprovalRequired = $DesiredApprovalAndDefaultRecipientState


                    if ($CurrentIsApprovalRequired -ne $DesiredIsApprovalRequired) {
                        Write-Host "The current Approval setting for Approval_EndUser_Assignment rule is $CurrentIsApprovalRequired for role $($Role.Name)."
                        Write-Host "The Approval setting of the Approval_EndUser_Assignment policy rule for $($Role.Name) is not configured as desired."

                        Write-Host "Its Approval requirement setting should be set to $DesiredApprovalAndDefaultRecipientState "

                        #Write-Host "  Current: $CurrentIsApprovalRequired, Desired: $DesiredIsApprovalRequired"
                        #$DriftSummary += "$($Role.Name) | Approval_EndUser_Assignment | Current=$CurrentIsApprovalRequired -> Desired=$DesiredIsApprovalRequired"
                        $DriftCounter += 1
                    } else {
                        Write-Host "The rule to require Approval upon activation for role $($Role.Name) is as desired."
                    }
                }

                # 2) Notification_Admin_EndUser_Assignment
                "Notification_Admin_EndUser_Assignment" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

                    $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients 
                    $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled
                       #($DesiredAdditionalNotificationRecipientState.Count -gt 0 -and 
                       #$null -ne (Compare-Object -ReferenceObject $CurrentAdditionalRecipients -DifferenceObject $DesiredAdditionalNotificationRecipientState)
                       ) {
                        Write-Host "The current default alert setting for Notification_Admin_EndUser_Assignment rule is $CurrentIsDefaultRecipientsEnabled for role $($Role.Name)."
                        Write-Host "The default alert setting for Notification_Admin_EndUser_Assignment policy rule for $($Role.Name) is not configured as desired."
                        Write-Host "Its default alert setting should be set to $DesiredApprovalAndDefaultRecipientState "

                        $DriftCounter += 1
                    } else {
                        Write-Host "Sending notifications to default recipients for Notification_Admin_EndUser_Assignment rule when eligible members activate the $($Role.Name) role is as desired."
                    }

                    # Check recipients that need to be removed or added
                    # 2. Second Check: Additional Recipients
                    # Initialize arrays to track changes needed
                    $RemoveRecipients = @()
                    $AddRecipients = @()

                    # Standardize the separators and create clean arrays for comparison
                    $CurrentRecipientsArray = $CurrentAdditionalRecipients | ForEach-Object { $_.Trim() }
                    $DesiredRecipientsArray = $DesiredAdditionalNotificationRecipientState -split ';' | ForEach-Object { $_.Trim() }

                    # Find recipients that need to be removed
                    foreach($Recipient in $CurrentRecipientsArray) {
                        if($DesiredRecipientsArray -notcontains $Recipient) {
                            $RemoveRecipients += $Recipient
                        }
                    }

                    # Find recipients that need to be added
                    foreach($Recipient in $DesiredRecipientsArray) {
                        if($CurrentRecipientsArray -notcontains $Recipient) {
                            $AddRecipients += $Recipient
                        }
                    }

                    # If any changes are needed to recipients list
                    if($RemoveRecipients.Count -gt 0 -or $AddRecipients.Count -gt 0) {
                        Write-Host "The Current Additional Recipients for Notification_Admin_EndUser_Assignment rule requires changes for role $($Role.Name)"
                        # Show what needs to be removed (if any)
                        if($RemoveRecipients.Count -gt 0) {
                            Write-Host "The Current Additional Recipients for Notification_Admin_EndUser_Assignment is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                            Write-Host "The Additional Recipients for Notification_Admin_EndUser_Assignment policy rule for $($Role.Name) is not configured as desired."
                            Write-Host "The following Additional Recipients should be removed: [$($RemoveRecipients -join ';')] to meet the Desired State [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                        }
                        # Show what needs to be added (if any)
                        if($AddRecipients.Count -gt 0) {
                            Write-Host "The Current Additional Recipients for Notification_Admin_EndUser_Assignment is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                            Write-Host "The Additional Recipients for Notification_Admin_EndUser_Assignment policy rule for $($Role.Name) is not configured as desired."
                            Write-Host "The following Additional Recipients should be added: [$($AddRecipients -join ';')] to meet the Desired State [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                        }
                        $DriftCounter += 1
                        
                    # if (($CurrentAdditionalRecipients -join ',') -ne ($DesiredAdditionalNotificationRecipientState -join ',')) {
                    #     Write-Host "The Current Additional Recipients for Notification_Admin_EndUser_Assignment rule is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                    #     Write-Host "The Additional Recipients for Notification_Admin_EndUser_Assignment policy rule for $($Role.Name) is not configured as desired."
                    #     Write-Host "Its Additional Recipients should be set to: [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                    

                    #     #Write-Host "  Current: $CurrentIsDefaultRecipientsEnabled, Desired: $DesiredIsDefaultRecipientsEnabled"
                    #     #$DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Current=$CurrentIsDefaultRecipientsEnabled -> Desired=$DesiredIsDefaultRecipientsEnabled"
                    #     $DriftCounter += 1
                    } else {
                        # If no changes needed to recipients list
                        Write-Host "Sending notifications to additional recipients for Notification_Admin_EndUser_Assignment rule when eligible members activate the $($Role.Name) role is as desired."

                    }
                }

                # 3) Notification_Admin_Admin_Eligibility
                "Notification_Admin_Admin_Eligibility" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

                    $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients 
                    $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled 
                       #($DesiredAdditionalNotificationRecipientState.Count -gt 0 -and 
                       #$null -ne (Compare-Object -ReferenceObject $CurrentAdditionalRecipients -DifferenceObject $DesiredAdditionalNotificationRecipientState)
                       ) {
                        Write-Host "The current default alert setting for Notification_Admin_Admin_Eligibility rule is $CurrentIsDefaultRecipientsEnabled for role $($Role.Name)."
                        Write-Host "The default alert setting for Notification_Admin_Admin_Eligibility policy rule for $($Role.Name) is not configured as desired."
                        Write-Host "Its default alert setting should be set to $DesiredApprovalAndDefaultRecipientState "

                        $DriftCounter += 1

                    } else {
                        Write-Host "Sending notifications to default recipients for Notification_Admin_Admin_Eligibility rule when eligible members activate the $($Role.Name) role is as desired."
                    }
                    
                    # Check recipients that need to be removed or added
                    $RemoveRecipients = @()
                    $AddRecipients = @()

                    # Standardize the separators and create clean arrays for comparison
                    $CurrentRecipientsArray = $CurrentAdditionalRecipients | ForEach-Object { $_.Trim() }
                    $DesiredRecipientsArray = $DesiredAdditionalNotificationRecipientState -split ';' | ForEach-Object { $_.Trim() }

                    foreach($Recipient in $CurrentRecipientsArray) {
                        if($DesiredRecipientsArray -notcontains $Recipient) {
                            $RemoveRecipients += $Recipient
                        }
                    }

                    foreach($Recipient in $DesiredRecipientsArray) {
                        if($CurrentRecipientsArray -notcontains $Recipient) {
                            $AddRecipients += $Recipient
                        }
                    }

                    if($RemoveRecipients.Count -gt 0 -or $AddRecipients.Count -gt 0) {
                        Write-Host "The Current Additional Recipients for Notification_Admin_Admin_Eligibility rule requires changes for role $($Role.Name)"
                        if($RemoveRecipients.Count -gt 0) {
                            Write-Host "The Current Additional Recipients for Notification_Admin_Admin_Eligibility is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                            Write-Host "The Additional Recipients for Notification_Admin_Admin_Eligibility policy rule for $($Role.Name) is not configured as desired."
                            Write-Host "The following Additional Recipients should be removed: [$($RemoveRecipients -join ';')] to meet the Desired State [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                        }
                        if($AddRecipients.Count -gt 0) {
                            Write-Host "The Current Additional Recipients for Notification_Admin_Admin_Eligibility is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                            Write-Host "The Additional Recipients for Notification_Admin_Admin_Eligibility policy rule for $($Role.Name) is not configured as desired."
                            Write-Host "The following Additional Recipients should be added: [$($AddRecipients -join ';')] to meet the Desired State [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                        }

                        $DriftCounter += 1

                    # if (($CurrentAdditionalRecipients -join ',') -ne ($DesiredAdditionalNotificationRecipientState -join ',')) {
                    #     Write-Host "The Current Additional Recipients for Notification_Admin_Admin_Eligibility rule is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                    #     Write-Host "The Additional Recipients for NNotification_Admin_Admin_Eligibility policy rule for $($Role.Name) is not configured as desired."
                    #     Write-Host "Its Additional Recipients should be set to: [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                    

                    #     #Write-Host "  Current: $CurrentIsDefaultRecipientsEnabled, Desired: $DesiredIsDefaultRecipientsEnabled"
                    #     #$DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Current=$CurrentIsDefaultRecipientsEnabled -> Desired=$DesiredIsDefaultRecipientsEnabled"
                    #     $DriftCounter += 1
                    } else {

                        Write-Host "Sending notifications to additional recipients for Notification_Admin_Admin_Eligibility rule when eligible members activate the $($Role.Name) role is as desired."

                    }
                }

                # 4) Notification_Admin_Admin_Assignment
                "Notification_Admin_Admin_Assignment" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

                    $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients 
                    $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled 
                       #($DesiredAdditionalNotificationRecipientState.Count -gt 0 -and 
                       #$null -ne (Compare-Object -ReferenceObject $CurrentAdditionalRecipients -DifferenceObject $DesiredAdditionalNotificationRecipientState)
                       ) {
                        Write-Host "The current default alert setting for Notification_Admin_Admin_Assignment rule is $CurrentIsDefaultRecipientsEnabled for role $($Role.Name)."
                        Write-Host "The default alert setting for Notification_Admin_Admin_Assignment policy rule for $($Role.Name) is not configured as desired."
                        Write-Host "Its default alert setting should be set to $DesiredApprovalAndDefaultRecipientState "

                        $DriftCounter += 1

                    } else {
                        Write-Host "Sending notifications to default recipients for Notification_Admin_Admin_Assignment rule when eligible members activate the $($Role.Name) role is as desired."
                    }

                    # Check recipients that need to be removed or added
                    $RemoveRecipients = @()
                    $AddRecipients = @()

                    # Standardize the separators and create clean arrays for comparison
                    $CurrentRecipientsArray = $CurrentAdditionalRecipients | ForEach-Object { $_.Trim() }
                    $DesiredRecipientsArray = $DesiredAdditionalNotificationRecipientState -split ';' | ForEach-Object { $_.Trim() }

                    foreach($Recipient in $CurrentRecipientsArray) {
                        if($DesiredRecipientsArray -notcontains $Recipient) {
                            $RemoveRecipients += $Recipient
                        }
                    }

                    foreach($Recipient in $DesiredRecipientsArray) {
                        if($CurrentRecipientsArray -notcontains $Recipient) {
                            $AddRecipients += $Recipient
                        }
                    }

                    if($RemoveRecipients.Count -gt 0 -or $AddRecipients.Count -gt 0) {
                        Write-Host "The Current Additional Recipients for Notification_Admin_Admin_Assignment rule requires changes for role $($Role.Name)"
                        if($RemoveRecipients.Count -gt 0) {
                            Write-Host "The Current Additional Recipients for Notification_Admin_Admin_Assignment is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                            Write-Host "The Additional Recipients for Notification_Admin_Admin_Assignment policy rule for $($Role.Name) is not configured as desired."
                            Write-Host "The following Additional Recipients should be removed: [$($RemoveRecipients -join ';')] to meet the Desired State [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                        }
                        if($AddRecipients.Count -gt 0) {
                            Write-Host "The Current Additional Recipients for Notification_Admin_Admin_Assignment is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                            Write-Host "The Additional Recipients for Notification_Admin_Admin_Assignment policy rule for $($Role.Name) is not configured as desired."
                            Write-Host "The following Additional Recipients should be added: [$($AddRecipients -join ';')] to meet the Desired State [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                        }

                        $DriftCounter += 1
                    
                    # if (($CurrentAdditionalRecipients -join ',') -ne ($DesiredAdditionalNotificationRecipientState -join ',')) {
                    #     Write-Host "The Current Additional Recipients for Notification_Admin_Admin_Assignment rule is : [$($CurrentAdditionalRecipients -join ',')] for role $($Role.Name)"
                    #     Write-Host "The Additional Recipients for Notification_Admin_Admin_Assignment policy rule for $($Role.Name) is not configured as desired."
                    #     Write-Host "Its Additional Recipients should be set to: [$($DesiredAdditionalNotificationRecipientState -join ',')]"
                    

                    #     #Write-Host "  Current: $CurrentIsDefaultRecipientsEnabled, Desired: $DesiredIsDefaultRecipientsEnabled"
                    #     #$DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Current=$CurrentIsDefaultRecipientsEnabled -> Desired=$DesiredIsDefaultRecipientsEnabled"
                    #     $DriftCounter += 1
                    } else {

                        Write-Host "Sending notifications to additional recipients  for Notification_Admin_Admin_Assignment rule when eligible members activate the $($Role.Name) role is as desired."

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
$DriftSummary = @()
Write-Host "DRIFT SUMMARY:"
if ($DriftCounter -gt 0) {
    foreach ($Role in $Roles) {
        $PolicyRules = $AllPolicyRules[$Role.Name]
        if (-not $PolicyRules) {continue} 
        
        foreach ($Rule in $PolicyRules) {
            switch ($Rule.Id) {
                # 1) Approval Rule for GA requires approval
                "Approval_EndUser_Assignment" {

                    if ($Role.Name -ne "Global Administrator") {
                        # Skip evaluating Approval rule for non-Global Admin roles
                        continue
                    }

                    $CurrentIsApprovalRequired = $Rule.AdditionalProperties.setting.isApprovalRequired

                    $DesiredIsApprovalRequired = $DesiredApprovalAndDefaultRecipientState 


                    if ($CurrentIsApprovalRequired -ne $DesiredIsApprovalRequired) {
                        $DriftSummary += "$($Role.Name) | Approval_EndUser_Assignment | Current=$CurrentIsApprovalRequired -> Desired=$DesiredIsApprovalRequired"
                    }
                    #  else {
                    #     $DriftSummary += "$($Role.Name) | Approval_EndUser_Assignment | Setting is configured as desired. No change is necessary."
                    # }
                } 

                # 2) Notification_Admin_EndUser_Assignment
                "Notification_Admin_EndUser_Assignment" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

                    $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients
                    $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled 
                       #($DesiredAdditionalNotificationRecipientState.Count -gt 0 -and 
                       #$null -ne (Compare-Object -ReferenceObject $CurrentAdditionalRecipients -DifferenceObject $DesiredAdditionalNotificationRecipientState)
                       ) {
                        $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Current=[Default Recipient Enabled:$CurrentIsDefaultRecipientsEnabled,Additional Recipients:$($CurrentAdditionalRecipients -join ';')] -> Desired=[Default Recipient Enabled:$DesiredIsDefaultRecipientsEnabled,Additional Recipients:$($DesiredAdditionalNotificationRecipientState -join ';')]"
                    } 
                    # else {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Default Recipients setting is configured as desired. No change is necessary."
                    # }
                    
                    # Check additional recipients
                    $RemoveRecipients = @()
                    $AddRecipients = @()

                    # Standardize the separators and create clean arrays
                    $CurrentRecipientsArray = $CurrentAdditionalRecipients | ForEach-Object { $_.Trim() }
                    $DesiredRecipientsArray = $DesiredAdditionalNotificationRecipientState -split ';' | ForEach-Object { $_.Trim() }

                    foreach($Recipient in $CurrentRecipientsArray) {
                        if($DesiredRecipientsArray -notcontains $Recipient) {
                            $RemoveRecipients += $Recipient
                        }
                    }

                    foreach($Recipient in $DesiredRecipientsArray) {
                        if($CurrentRecipientsArray -notcontains $Recipient) {
                            $AddRecipients += $Recipient
                        }
                    }

                    if($RemoveRecipients.Count -gt 0 -or $AddRecipients.Count -gt 0) {
                        if($RemoveRecipients.Count -gt 0) {
                            $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Recipients to remove: [$($RemoveRecipients -join ';')]"
                        }
                        if($AddRecipients.Count -gt 0) {
                            $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Recipients to add: [$($AddRecipients -join ';')]"
                        }
                    } 
                    # else {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Additional Recipients are configured as desired. No change is necessary."
                    # }
                    # if (($CurrentAdditionalRecipients -join ',') -ne ($DesiredAdditionalNotificationRecipientState -join ',')) 
                    #     {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Additional Recipients: Current=[$($CurrentAdditionalRecipients -join ';')] -> Desired=[$($DesiredAdditionalNotificationRecipientState -join ';')]"
                    # }

                } 

                # 3) Notification_Admin_Admin_Eligibility
                "Notification_Admin_Admin_Eligibility" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

                    $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients
                    $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled 
                       #($DesiredAdditionalNotificationRecipientState.Count -gt 0 -and 
                       #$null -ne (Compare-Object -ReferenceObject $CurrentAdditionalRecipients -DifferenceObject $DesiredAdditionalNotificationRecipientState)
                       ) {
                        $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Current=[Default Recipient Enabled:$CurrentIsDefaultRecipientsEnabled,Additional Recipients:$($CurrentAdditionalRecipients -join ';')] -> Desired=[Default Recipient Enabled:$DesiredIsDefaultRecipientsEnabled,Additional Recipients:$($DesiredAdditionalNotificationRecipientState -join ';')]"
                    } 
                    # else {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Default Recipients setting is configured as desired. No change is necessary."
                    # }

                    # Check additional recipients
                    $RemoveRecipients = @()
                    $AddRecipients = @()

                    # Standardize the separators and create clean arrays
                    $CurrentRecipientsArray = $CurrentAdditionalRecipients | ForEach-Object { $_.Trim() }
                    $DesiredRecipientsArray = $DesiredAdditionalNotificationRecipientState -split ';' | ForEach-Object { $_.Trim() }

                    foreach($Recipient in $CurrentRecipientsArray) {
                        if($DesiredRecipientsArray -notcontains $Recipient) {
                            $RemoveRecipients += $Recipient
                        }
                    }

                    foreach($Recipient in $DesiredRecipientsArray) {
                        if($CurrentRecipientsArray -notcontains $Recipient) {
                            $AddRecipients += $Recipient
                        }
                    }

                    if($RemoveRecipients.Count -gt 0 -or $AddRecipients.Count -gt 0) {
                        if($RemoveRecipients.Count -gt 0) {
                            $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Recipients to remove: [$($RemoveRecipients -join ';')]"
                        }
                        if($AddRecipients.Count -gt 0) {
                            $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Recipients to add: [$($AddRecipients -join ';')]"
                        }
                    } 
                    # else {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Additional Recipients are configured as desired. No change is necessary."
                    # }

                    # if (($CurrentAdditionalRecipients -join ',') -ne ($DesiredAdditionalNotificationRecipientState -join ',')) 
                    #     {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Additional Recipients: Current=[$($CurrentAdditionalRecipients -join ';')] -> Desired=[$($DesiredAdditionalNotificationRecipientState -join ';')]"

                    # }
                }

                # 4) Notification_Admin_Admin_Assignment
                "Notification_Admin_Admin_Assignment" {
                    $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

                    $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients
                    $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState

                    if ($CurrentIsDefaultRecipientsEnabled -ne $DesiredIsDefaultRecipientsEnabled 
                       #($DesiredAdditionalNotificationRecipientState.Count -gt 0 -and 
                       #$null -ne (Compare-Object -ReferenceObject $CurrentAdditionalRecipients -DifferenceObject $DesiredAdditionalNotificationRecipientState)
                       ) {
                        $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Current=[Default Recipient Enabled:$CurrentIsDefaultRecipientsEnabled,Additional Recipients:$($CurrentAdditionalRecipients -join ';')] -> Desired=[Default Recipient Enabled:$DesiredIsDefaultRecipientsEnabled,Additional Recipients:$($DesiredAdditionalNotificationRecipientState -join ';')]"
                    } 
                    # else {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Default Recipients setting is configured as desired. No change is necessary."
                    # }

                    # Check additional recipients
                    $RemoveRecipients = @()
                    $AddRecipients = @()

                    # Standardize the separators and create clean arrays
                    $CurrentRecipientsArray = $CurrentAdditionalRecipients | ForEach-Object { $_.Trim() }
                    $DesiredRecipientsArray = $DesiredAdditionalNotificationRecipientState -split ';' | ForEach-Object { $_.Trim() }

                    foreach($Recipient in $CurrentRecipientsArray) {
                        if($DesiredRecipientsArray -notcontains $Recipient) {
                            $RemoveRecipients += $Recipient
                        }
                    }

                    foreach($Recipient in $DesiredRecipientsArray) {
                        if($CurrentRecipientsArray -notcontains $Recipient) {
                            $AddRecipients += $Recipient
                        }
                    }

                    if($RemoveRecipients.Count -gt 0 -or $AddRecipients.Count -gt 0) {
                        if($RemoveRecipients.Count -gt 0) {
                            $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Recipients to remove: [$($RemoveRecipients -join ';')]"
                        }
                        if($AddRecipients.Count -gt 0) {
                            $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Recipients to add: [$($AddRecipients -join ';')]"
                        }
                    } 
                    # else {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Additional Recipients are configured as desired. No change is necessary."
                    # }

                    # if (($CurrentAdditionalRecipients -join ',') -ne ($DesiredAdditionalNotificationRecipientState -join ',')) 
                    #     {
                    #     $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Additional Recipients: Current=[$($CurrentAdditionalRecipients -join ';')] -> Desired=[$($DesiredAdditionalNotificationRecipientState -join ';')]"

                    # }
                }                
            }
        }
    }    
} 

# else {

#     foreach ($Role in $Roles) {
#         $PolicyRules = $AllPolicyRules[$Role.Name]
#         if (-not $PolicyRules) {continue}     

#         foreach ($Rule in $PolicyRules) {
#             switch ($Rule.Id) {

#                 # 1) Approval Rule for GA requires approval
#                 "Approval_EndUser_Assignment" {

#                     if ($Role.Name -ne "Global Administrator") {
#                         # Skip evaluating Approval rule for non-Global Admin roles
#                         continue
#                     }

#                     $CurrentIsApprovalRequired = $Rule.AdditionalProperties.setting.isApprovalRequired

#                     $DesiredIsApprovalRequired = $DesiredApprovalAndDefaultRecipientState


#                     $DriftSummary += "$($Role.Name) | Approval_EndUser_Assignment | Setting is configured as desired. No change is necessary."
#                 }

#                 # 2) Notification_Admin_EndUser_Assignment
#                 "Notification_Admin_EndUser_Assignment" {
#                     $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

#                     $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients
#                     $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState
                    


#                     $DriftSummary += "$($Role.Name) | Notification_Admin_EndUser_Assignment | Setting is configured as desired. No change is necessary."
#                 }     

#                 # 3) Notification_Admin_Admin_Eligibility
#                 "Notification_Admin_Admin_Eligibility" {
#                     $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

#                     $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients
#                     $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState


#                     $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Eligibility | Setting is configured as desired. No change is necessary."
#                 }

#                 # 4) Notification_Admin_Admin_Assignment
#                 "Notification_Admin_Admin_Assignment" {
#                     $CurrentIsDefaultRecipientsEnabled = $Rule.AdditionalProperties.isDefaultRecipientsEnabled

#                     $CurrentAdditionalRecipients = $Rule.AdditionalProperties.notificationRecipients
#                     $DesiredIsDefaultRecipientsEnabled = $DesiredApprovalAndDefaultRecipientState


#                     $DriftSummary += "$($Role.Name) | Notification_Admin_Admin_Assignment | Setting is configured as desired. No change is necessary."
#                 }    
#             }
#         }
#     }        
# }

if ($DriftSummary.Count -gt 0) {
    $currentRole = ""
    $DriftSummary | ForEach-Object {
        $parts = $_ -split ' \| '
        if ($currentRole -ne $parts[0]) {
            if ($currentRole -ne "") { Write-Host "" }  # Add line break between roles
            $currentRole = $parts[0]
            Write-Host "$($currentRole):"
        }
        $ruleName = $parts[1] -replace '_', ' '
        $details = $parts[2]
        Write-Host "     $ruleName`: $details"
    }
} else {
    foreach ($Role in $Roles) {
        Write-Host "$($Role.Name):"
        Write-Host "     No drift detected. The current state aligns with the desired state."
        Write-Host ""
    }
}
#$DriftSummary | ForEach-Object { Write-Host $_ }
# Format and display Drift Summary
# $currentRole = ""
# $DriftSummary | ForEach-Object {
#     $parts = $_ -split ' \| '
#     if ($currentRole -ne $parts[0]) {
#         if ($currentRole -ne "") { Write-Host "" }  # Add line break between roles
#         $currentRole = $parts[0]
#         Write-Host $currentRole
#     }
#     $ruleName = $parts[1] -replace '_', ' '
#     $details = $parts[2]
#     Write-Host "     $ruleName`: $details"
# }

    # Summarize Current State
    Write-Host "====================================================================================================" 
    Write-Host "------------------- CURRENT STATE OF PIM SETTINGS FOR HIGHLY PRIVILEGED ROLES --------------------"
    Write-Host "===================================================================================================="
    
    if($Iteration -gt 0) {
        Write-Host "------------- Current State of Pim Settings For Highly Privileged Roles After Changes ---------------"
    }
    else {
        Write-Host "------------- Current State of Pim Settings For Highly Privileged Roles Before Changes --------------"
    } 
    Write-Host "===================================================================================================="

    foreach ($Role in $Roles) {
        Write-Host "Role: $($Role.Name):"
        $PolicyRules = $AllPolicyRules[$Role.Name]
        if (-not $PolicyRules) {continue}
    
        foreach ($Rule in $PolicyRules) {
            switch ($Rule.Id) {

                # 1) Approval Rule for GA requires approval
                "Approval_EndUser_Assignment" {

                    if ($Role.Name -ne "Global Administrator") {
                        # Skip evaluating Approval rule for non-Global Admin roles
                        continue
                    }
                    Write-Host "      Approval EndUser Assignment: Approval Configuration: $($Rule.AdditionalProperties.setting.isApprovalRequired)"
                }
                
                # 2) Notification_Admin_EndUser_Assignment
                "Notification_Admin_EndUser_Assignment" {

                    Write-Host "      Notification Admin EndUser Assignment: Default Alert Recipient Configuration: $($Rule.AdditionalProperties.isDefaultRecipientsEnabled)"
                    Write-Host "     Additional Recipients: [$($Rule.AdditionalProperties.notificationRecipients -join ',')]"

                }

                # 3) Notification_Admin_Admin_Eligibility
                "Notification_Admin_Admin_Eligibility" {

                    Write-Host "      Notification Admin Eligibility: Default Alert Recipient Configuration: $($Rule.AdditionalProperties.isDefaultRecipientsEnabled)"
                    Write-Host "      Additional Recipients: [$($Rule.AdditionalProperties.notificationRecipients -join ',')]"

                }

                # 4) Notification_Admin_Admin_Assignment
                "Notification_Admin_Admin_Assignment" {

                    Write-Host "      Notification Admin Assignment: Default Alert Recipient Configuration: $($Rule.AdditionalProperties.isDefaultRecipientsEnabled)"
                    Write-Host "      Additional Recipients: [$($Rule.AdditionalProperties.notificationRecipients -join ',')]"

                }               
            }
        }
    }    

    $Iteration += 1

    Write-Host "===================================================================================================="
    if ($DriftCounter -gt 0) { 
        Write-Host "DRIFT DETECTED: THE CURRENT STATE DOES NOT ALIGN WITH THE DESIRED STATE FOR SOME RULES OF SOME HIGHLY PRIVILEGED ROLES"
    }
    else {
        Write-Host "NO DRIFT DETECTED: THE CURRENT STATE ALIGNS WITH THE DESIRED STATE FOR ALL HIGHLY PRIVILEGED ROLES"
    }
    Write-Host "===================================================================================================="

    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }

}
