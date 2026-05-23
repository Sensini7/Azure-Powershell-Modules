function Compare-CrossTenantAccessSettingDefaults {

    # Compile the current state of the setting
    Write-Host "Now compiling current state configuration of default Entra B2B Organization Relationship settings."
	$CurrentCrossTenantAccessSettingDefaults = Get-MgPolicyCrossTenantAccessPolicyDefault

    $CurrentAccessSettings = @{
        b2bCollaborationInboundAccessType = $CurrentCrossTenantAccessSettingDefaults.b2bCollaborationInbound.usersAndGroups.accessType
        b2bCollaborationInboundTarget = $CurrentCrossTenantAccessSettingDefaults.b2bCollaborationInbound.usersAndGroups.targets.target
        b2bCollaborationInboundApplications = $CurrentCrossTenantAccessSettingDefaults.b2bCollaborationInbound.applications.targets
        b2bCollaborationOutboundAccessType = $CurrentCrossTenantAccessSettingDefaults.b2bCollaborationOutbound.usersAndGroups.accessType
        b2bCollaborationOutboundTarget = $CurrentCrossTenantAccessSettingDefaults.b2bCollaborationOutbound.usersAndGroups.targets.target
        b2bCollaborationOutboundApplications = $CurrentCrossTenantAccessSettingDefaults.b2bCollaborationOutbound.applications.targets
        b2bDirectConnectInboundAccessType = $CurrentCrossTenantAccessSettingDefaults.b2bDirectConnectInbound.usersAndGroups.accessType
        b2bDirectConnectInboundTarget = $CurrentCrossTenantAccessSettingDefaults.b2bDirectConnectInbound.usersAndGroups.targets.target
        b2bDirectConnectInboundApplications = $CurrentCrossTenantAccessSettingDefaults.b2bDirectConnectInbound.applications.targets
        b2bDirectConnectOutboundAccessType = $CurrentCrossTenantAccessSettingDefaults.b2bDirectConnectOutbound.usersAndGroups.accessType
        b2bDirectConnectOutboundTarget = $CurrentCrossTenantAccessSettingDefaults.b2bDirectConnectOutbound.usersAndGroups.targets.target
        b2bDirectConnectOutboundApplications = $CurrentCrossTenantAccessSettingDefaults.b2bDirectConnectOutbound.applications.targets
    }

    $CurrentInboundTrustSettings = @{
        IsCompliantDeviceAccepted = $CurrentCrossTenantAccessSettingDefaults.InboundTrust.IsCompliantDeviceAccepted
        IsHybridAzureADJoinedDeviceAccepted = $CurrentCrossTenantAccessSettingDefaults.InboundTrust.IsHybridAzureADJoinedDeviceAccepted
        IsMfaAccepted = $CurrentCrossTenantAccessSettingDefaults.InboundTrust.IsMfaAccepted
    }

    ### Calculate drift of the current state from the desired state

    $DriftCounter = 0

    ## Evaluate B2B Collaboration Inbound settings
    # Evaluate b2bCollaborationInboundAccessType
    if($CurrentAccessSettings.b2bCollaborationInboundAccessType -ne $params.b2bCollaborationInbound.usersAndGroups.accessType)
    {
        Write-Host "B2B Collaboration Inbound Access Type is not configured as expected. It should be set to $($params.b2bCollaborationInbound.usersAndGroups.accessType)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Collaboration Inbound Access Type is configured as expected. No change is necessary."
    }

    # Evaluate b2bCollaborationInboundTarget
    if($CurrentAccessSettings.b2bCollaborationInboundTarget -ne $params.b2bCollaborationInbound.usersAndGroups.targets.target)
    {
        Write-Host "B2B Collaboration Inbound Target is not configured as expected. It should be set to $($params.b2bCollaborationInbound.usersAndGroups.targets.target)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Collaboration Inbound Target is configured as expected. No change is necessary."
    }

    # Evaluate b2bCollaborationInboundApplications
    Write-Host "Now evaluating the B2B Collaboration Inbound Application List."
    $InboundCollaborationDrift = Compare-B2BApplicationList -CurrentApplicationList $CurrentAccessSettings.b2bCollaborationInboundApplications -DesiredApplicationList $params.b2bCollaborationInbound.applications.targets
    $DriftCounter += $InboundCollaborationDrift["DriftCounter"]

    ## Evaluate B2B Collaboration Outbound settings
    # Evaluate b2bCollaborationOutboundAccessType
    if($CurrentAccessSettings.b2bCollaborationOutboundAccessType -ne $params.b2bCollaborationOutbound.usersAndGroups.accessType)
    {
        Write-Host "B2B Collaboration Outbound Access Type is not configured as expected. It should be set to $($params.b2bCollaborationOutbound.usersAndGroups.accessType)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Collaboration Outbound Access Type is configured as expected. No change is necessary."
    }

    # Evaluate b2bCollaborationOutboundTarget
    if($CurrentAccessSettings.b2bCollaborationOutboundTarget -ne $params.b2bCollaborationOutbound.usersAndGroups.targets.target)
    {
        Write-Host "B2B Collaboration Outbound Target is not configured as expected. It should be set to $($params.b2bCollaborationOutbound.usersAndGroups.targets.target)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Collaboration Outbound Target is configured as expected. No change is necessary."
    }
    
    # Evaluate b2bCollaborationOutboundApplications
    Write-Host "Now evaluating the B2B Collaboration Outbound Application List."
    $OutboundCollaborationDrift = Compare-B2BApplicationList -CurrentApplicationList $CurrentAccessSettings.b2bCollaborationOutboundApplications -DesiredApplicationList $params.b2bCollaborationOutbound.applications.targets
    $DriftCounter += $OutboundCollaborationDrift["DriftCounter"]

    ## Evaluate B2B Direct Connect Inbound settings
    # Evaluate b2bDirectConnectInboundAccessType
    if($CurrentAccessSettings.b2bDirectConnectInboundAccessType -ne $params.b2bDirectConnectInbound.usersAndGroups.accessType)
    {
        Write-Host "B2B Direct Connect Inbound Access Type is not configured as expected. It should be set to $($params.b2bDirectConnectInbound.usersAndGroups.accessType)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Direct Connect Inbound Access Type is configured as expected. No change is necessary."
    }

    # Evaluate b2bDirectConnectInboundTarget
    if($CurrentAccessSettings.b2bDirectConnectInboundTarget -ne $params.b2bDirectConnectInbound.usersAndGroups.targets.target)
    {
        Write-Host "B2B Direct Connect Inbound Target is not configured as expected. It should be set to $($params.b2bDirectConnectInbound.usersAndGroups.targets.target)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Direct Connect Inbound Target is configured as expected. No change is necessary."
    }

    # Evaluate b2bDirectConnectInboundApplications
    Write-Host "Now evaluating the B2B Direct Connect Inbound Application List."
    $InboundDirectConnectDrift = Compare-B2BApplicationList -CurrentApplicationList $CurrentAccessSettings.b2bDirectConnectInboundApplications -DesiredApplicationList $params.b2bDirectConnectInbound.applications.targets
    $DriftCounter += $InboundDirectConnectDrift["DriftCounter"]

    ## Evaluate B2B Direct Connect Outbound settings
    # Evaluate b2bDirectConnectOutboundAccessType
    if($CurrentAccessSettings.b2bDirectConnectOutboundAccessType -ne $params.b2bDirectConnectOutbound.usersAndGroups.accessType)
    {
        Write-Host "B2B Direct Connect Outbound Access Type is not configured as expected. It should be set to $($params.b2bDirectConnectOutbound.usersAndGroups.accessType)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Direct Connect Outbound Access Type is configured as expected. No change is necessary."
    }

    # Evaluate b2bDirectConnectOutboundTarget
    if($CurrentAccessSettings.b2bDirectConnectOutboundTarget -ne $params.b2bDirectConnectOutbound.usersAndGroups.targets.target)
    {
        Write-Host "B2B Direct Connect Outbound Target is not configured as expected. It should be set to $($params.b2bDirectConnectOutbound.usersAndGroups.targets.target)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Direct Connect Outbound Target is configured as expected. No change is necessary."
    }

    # Evaluate b2bDirectConnectOutboundApplications
    Write-Host "Now evaluating the B2B Direct Connect Outbound Application List."
    $OutboundDirectConnectDrift = Compare-B2BApplicationList -CurrentApplicationList $CurrentAccessSettings.b2bDirectConnectOutboundApplications -DesiredApplicationList $params.b2bDirectConnectOutbound.applications.targets
    $DriftCounter += $OutboundDirectConnectDrift["DriftCounter"]

    ## Evaluate Inbound Trust Settings
    # Evaluate IsCompliantDeviceAccepted
    if($CurrentInboundTrustSettings.IsCompliantDeviceAccepted -ne $params.inboundTrust.IsCompliantDeviceAccepted)
    {
        Write-Host "B2B Compliance Device Trust setting is not configured as expected. It should be set to $($params.inboundTrust.IsCompliantDeviceAccepted)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Compliance Device Trust setting is configured as expected. No change is necessary."
    }

    # Evaluate IsHybridAzureADJoinedDeviceAccepted
    if($CurrentInboundTrustSettings.IsHybridAzureADJoinedDeviceAccepted -ne $params.inboundTrust.IsHybridAzureADJoinedDeviceAccepted)
    {
        Write-Host "B2B Hybrid Join Device Trust setting is not configured as expected. It should be set to $($params.inboundTrust.IsHybridAzureADJoinedDeviceAccepted)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B Hybrid Join Device Trust setting is configured as expected. No change is necessary."
    }

    # Evaluate IsMfaAccepted
    if($CurrentInboundTrustSettings.IsMfaAccepted -ne $params.inboundTrust.IsMfaAccepted)
    {
        Write-Host "B2B MFA Trust setting is not configured as expected. It should be set to $($params.inboundTrust.IsMfaAccepted)."
        $DriftCounter += 1
    }
    else
    {
        Write-Host "B2B MFA Trust setting is configured as expected. No change is necessary."
    }

    Write-Host "----------------------------------------------------------------------------------------------------"
    
    ### Summarize drift
    $DriftSummary = @()
    Write-Host "DRIFT SUMMARY:"
    if($DriftCounter -gt 0)
    {
        # Evaluate b2bCollaborationInboundAccessType
        if($CurrentAccessSettings.b2bCollaborationInboundAccessType -ne $params.b2bCollaborationInbound.usersAndGroups.accessType)
        {
            $DriftSummary += Write-Output "CURRENT: Inbound Collaboration access status is $($CurrentAccessSettings.b2bCollaborationInboundAccessType) -> DESIRED: Access status should be $($params.b2bCollaborationInbound.usersAndGroups.accessType)"
        }

        # Evaluate b2bCollaborationInboundTarget
        if($CurrentAccessSettings.b2bCollaborationInboundTarget -ne $params.b2bCollaborationInbound.usersAndGroups.targets.target)
        {
            $DriftSummary += Write-Output "CURRENT: Inbound Collaboration access target is $($CurrentAccessSettings.b2bCollaborationInboundTarget) -> DESIRED: Access target should be $($params.b2bCollaborationInbound.usersAndGroups.targets.target)"
        }

        # Evaluate b2bCollaborationInboundApplications
        if($InboundCollaborationDrift["RemoveApplicationList"].Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Inbound Collaboration app list includes apps which are not in the desired state -> DESIRED: Remove these apps from the list:"
            $InboundCollaborationDrift["RemoveApplicationList"] | foreach { $DriftSummary += Write-Output "`t$_" }
        }
        if($InboundCollaborationDrift["AddApplicationList"].Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Inbound Collaboration app list is missing apps which are in the desired state -> DESIRED: Add these apps to the list:"
            $InboundCollaborationDrift["AddApplicationList"] | foreach { $DriftSummary += Write-Output "`t$_" }
        }

        ## Evaluate B2B Collaboration Outbound settings
        # Evaluate b2bCollaborationOutboundAccessType
        if($CurrentAccessSettings.b2bCollaborationOutboundAccessType -ne $params.b2bCollaborationOutbound.usersAndGroups.accessType)
        {
            $DriftSummary += Write-Output "CURRENT: Outbound Collaboration access status is $($CurrentAccessSettings.b2bCollaborationOutboundAccessType) -> DESIRED: Access status should be $($params.b2bCollaborationOutbound.usersAndGroups.accessType)"
        }

        # Evaluate b2bCollaborationOutboundTarget
        if($CurrentAccessSettings.b2bCollaborationOutboundTarget -ne $params.b2bCollaborationOutbound.usersAndGroups.targets.target)
        {
            $DriftSummary += Write-Output "CURRENT: Outbound Collaboration access target is $($CurrentAccessSettings.b2bCollaborationOutboundTarget) -> DESIRED: Access target should be $($params.b2bCollaborationOutbound.usersAndGroups.targets.target)"
        }
        
        # Evaluate b2bCollaborationOutboundApplications
        if($OutboundCollaborationDrift["RemoveApplicationList"].Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Outbound Collaboration app list includes apps which are not in the desired state -> DESIRED: Remove these apps from the list:"
            $OutboundCollaborationDrift["RemoveApplicationList"] | foreach { $DriftSummary += Write-Output "`t$_" }
        }
        if($OutboundCollaborationDrift["AddApplicationList"].Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Outbound Collaboration app list is missing apps which are in the desired state -> DESIRED: Add these apps to the list:"
            $OutboundCollaborationDrift["AddApplicationList"] | foreach { $DriftSummary += Write-Output "`t$_" }
        }

        ## Evaluate B2B Direct Connect Inbound settings
        # Evaluate b2bDirectConnectInboundAccessType
        if($CurrentAccessSettings.b2bDirectConnectInboundAccessType -ne $params.b2bDirectConnectInbound.usersAndGroups.accessType)
        {
            $DriftSummary += Write-Output "CURRENT: Inbound Direct Connect access status is $($CurrentAccessSettings.b2bDirectConnectInboundAccessType) -> DESIRED: Access status should be $($params.b2bDirectConnectInbound.usersAndGroups.accessType)"
        }

        # Evaluate b2bDirectConnectInboundTarget
        if($CurrentAccessSettings.b2bDirectConnectInboundTarget -ne $params.b2bDirectConnectInbound.usersAndGroups.targets.target)
        {
            $DriftSummary += Write-Output "CURRENT: Inbound Direct Connect access target is $($CurrentAccessSettings.b2bDirectConnectInboundTarget) -> DESIRED: Access target should be $($params.b2bDirectConnectInbound.usersAndGroups.targets.target)"
        }

        # Evaluate b2bDirectConnectInboundApplications
        if($InboundDirectConnectDrift["RemoveApplicationList"].Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Inbound Direct Connect app list includes apps which are not in the desired state -> DESIRED: Remove these apps from the list:"
            $InboundDirectConnectDrift["RemoveApplicationList"] | foreach { $DriftSummary += Write-Output "`t$_" }
        }
        if($InboundDirectConnectDrift["AddApplicationList"].Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Inbound Direct Connect app list is missing apps which are in the desired state -> DESIRED: Add these apps to the list:"
            $InboundDirectConnectDrift["AddApplicationList"] | foreach { $DriftSummary += Write-Output "`t$_" }
        }

        ## Evaluate B2B Direct Connect Outbound settings
        # Evaluate b2bDirectConnectOutboundAccessType
        if($CurrentAccessSettings.b2bDirectConnectOutboundAccessType -ne $params.b2bDirectConnectOutbound.usersAndGroups.accessType)
        {
            $DriftSummary += Write-Output "CURRENT: Outbound Direct Connect access status is $($CurrentAccessSettings.b2bDirectConnectOutboundAccessType) -> DESIRED: Access status should be $($params.b2bDirectConnectOutbound.usersAndGroups.accessType)"
        }

        # Evaluate b2bDirectConnectOutboundTarget
        if($CurrentAccessSettings.b2bDirectConnectOutboundTarget -ne $params.b2bDirectConnectOutbound.usersAndGroups.targets.target)
        {
            $DriftSummary += Write-Output "CURRENT: Outbound Direct Connect access target is $($CurrentAccessSettings.b2bDirectConnectOutboundTarget) -> DESIRED: Access target should be $($params.b2bDirectConnectOutbound.usersAndGroups.targets.target)"
        }

        # Evaluate b2bDirectConnectOutboundApplications
        if($OutboundDirectConnectDrift["RemoveApplicationList"].Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Outbound Direct Connect app list includes apps which are not in the desired state -> DESIRED: Remove these apps from the list:"
            $OutboundDirectConnectDrift["RemoveApplicationList"] | foreach { $DriftSummary += Write-Output "`t$_" }
        }
        if($OutboundDirectConnectDrift["AddApplicationList"].Count -gt 0)
        {
            $DriftSummary += Write-Output "CURRENT: Outbound Direct Connect app list is missing apps which are in the desired state -> DESIRED: Add these apps to the list:"
            $OutboundDirectConnectDrift["AddApplicationList"] | foreach { $DriftSummary += Write-Output "`t$_" }
        }

        ## Evaluate Inbound Trust Settings
        # Evaluate IsCompliantDeviceAccepted
        if($CurrentInboundTrustSettings.IsCompliantDeviceAccepted -ne $params.inboundTrust.IsCompliantDeviceAccepted)
        {
            $DriftSummary += Write-Output "CURRENT: B2B Compliance Device Trust setting is $($CurrentInboundTrustSettings.IsCompliantDeviceAccepted) -> DESIRED: Setting should be $($params.inboundTrust.IsCompliantDeviceAccepted)"
        }

        # Evaluate IsHybridAzureADJoinedDeviceAccepted
        if($CurrentInboundTrustSettings.IsHybridAzureADJoinedDeviceAccepted -ne $params.inboundTrust.IsHybridAzureADJoinedDeviceAccepted)
        {
            $DriftSummary += Write-Output "CURRENT: B2B Hybrid Join Device Trust setting is $($CurrentInboundTrustSettings.IsHybridAzureADJoinedDeviceAccepted) -> DESIRED: Setting should be $($params.inboundTrust.IsHybridAzureADJoinedDeviceAccepted)"
        }

        # Evaluate IsMfaAccepted
        if($CurrentInboundTrustSettings.IsMfaAccepted -ne $params.inboundTrust.IsMfaAccepted)
        {
            $DriftSummary += Write-Output "CURRENT: B2B MFA Trust setting is $($CurrentInboundTrustSettings.IsMfaAccepted) -> DESIRED: Setting should be $($params.inboundTrust.IsMfaAccepted)"
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
        Write-Host "------- Current State of Default Entra B2B Organization Relationship Settings After Changes --------"
    }
    else {
        Write-Host "------- Current State of Default Entra B2B Organization Relationship Settings Before Changes -------"
    }
    Write-Host "B2B Collaboration Settings:"
    Write-Host "`tb2bCollaborationInboundAccessType:" $CurrentAccessSettings.b2bCollaborationInboundAccessType
    Write-Host "`tb2bCollaborationInboundTarget:" $CurrentAccessSettings.b2bCollaborationInboundTarget
    Write-Host "`tTarget applications:"
    foreach($Application in $CurrentAccessSettings.b2bCollaborationInboundApplications)
    {
        $ApplicationName = $Application.target
        Write-Host `t`t$ApplicationName
    }
    Write-Host "`tb2bCollaborationOutboundAccessType:" $CurrentAccessSettings.b2bCollaborationOutboundAccessType
    Write-Host "`tb2bCollaborationOutboundTarget:" $CurrentAccessSettings.b2bCollaborationOutboundTarget
    foreach($Application in $CurrentAccessSettings.b2bCollaborationOutboundApplications)
    {
        $ApplicationName = $Application.target
        Write-Host `t`t$ApplicationName
    }
    Write-Host "B2B Direct Connect Settings:"
    Write-Host "`tb2bDirectConnectInboundAccessType:" $CurrentAccessSettings.b2bDirectConnectInboundAccessType
    Write-Host "`tb2bDirectConnectInboundTarget:" $CurrentAccessSettings.b2bDirectConnectInboundTarget
    foreach($Application in $CurrentAccessSettings.b2bDirectConnectInboundApplications)
    {
        $ApplicationName = $Application.target
        Write-Host `t`t$ApplicationName
    }
    Write-Host "`tb2bDirectConnectOutboundAccessType:" $CurrentAccessSettings.b2bDirectConnectOutboundAccessType
    Write-Host "`tb2bDirectConnectOutboundTarget:" $CurrentAccessSettings.b2bDirectConnectOutboundTarget
    foreach($Application in $CurrentAccessSettings.b2bDirectConnectOutboundApplications)
    {
        $ApplicationName = $Application.target
        Write-Host `t`t$ApplicationName
    }
    Write-Host "Inbound Trust Settings:"
    Write-Host "`tIsCompliantDeviceAccepted:" $CurrentInboundTrustSettings.IsCompliantDeviceAccepted
    Write-Host "`tIsHybridAzureADJoinedDeviceAccepted:" $CurrentInboundTrustSettings.IsHybridAzureADJoinedDeviceAccepted
    Write-Host "`tIsMfaAccepted:" $CurrentInboundTrustSettings.IsMfaAccepted

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
    
    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }

}