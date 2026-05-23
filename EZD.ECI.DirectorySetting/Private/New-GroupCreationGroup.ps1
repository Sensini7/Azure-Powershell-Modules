function Get-GroupCreatorsGroup {
    
    # If a GroupCreationAllowedGroupId was not passed to the function, try to retrieve an ID from an existing group
    if(!$GroupCreationAllowedGroupId) 
    {
        $GroupCreationAllowedGroupId = (Get-MgGroup -Filter "DisplayName eq '$GroupCreationGroupName'").Id
    }

    # If no GroupCreationAllowedGroupId is retrieved from the prior query, report back that it needs to be created
    if(!$GroupCreationAllowedGroupId)
    {
        Write-Host "Group creation group with Display Name $GroupCreationGroupName not found in the tenant. It should be created."
    }
    else
    {
        Write-Host "Group creation group with Display Name $GroupCreationGroupName currently exists. This is expected. Proceeding."
        return $GroupCreationAllowedGroupId
    }
    return $GroupCreationAllowedGroupId
}

function New-GroupCreatorsGroup {

    # Specify Group Creation Group Name
    $GroupCreationGroupName = "Microsoft 365 Group Creators"
    $GroupCreationGroupNameTrimmed = $GroupCreationGroupName -replace "\s+",""

    # Check if Group Creators Group already exists
    Write-Host "Now evaluating whether Group Creators Group currently exists."
    $CreatorGroupPreResults = Get-GroupCreatorsGroup
    $GroupCreationAllowedGroupId = $CreatorGroupPreResults

    # If this is a drift detection run, end the function
	if (-Not ($ExecuteChange)) 
	{
        Write-Host "This is a drift detection run. No changes will be made."
    }
    else
    {
        # Execute the change
        if(!$GroupCreationAllowedGroupId)
        {
            Write-Host "-----------------------------------------------------------------------------------------------------"
            Write-Host "Now deploying new Group Creators Group with Display Name $GroupCreationGroupName."
            $GroupCreationAllowedGroupId = New-MgGroup -DisplayName $GroupCreationGroupName -SecurityEnabled -MailEnabled:$False -Description "Users allowed to create Microsoft 365 Groups." -MailNickName $GroupCreationGroupNameTrimmed | Select -ExpandProperty Id
            Write-Host "-----------------------------------------------------------------------------------------------------"

            # Check if Group Creators Group already exists
            $GroupCreationAllowedGroupId = $null
            $CreatorGroupPostResults = Get-GroupCreatorsGroup
            $GroupCreationAllowedGroupId = $CreatorGroupPostResults
        }
    }

    return $GroupCreationAllowedGroupId
}