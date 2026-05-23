function Set-GroupCreatorsGroup {
	param (
		[switch] $EnableGroupCreationForAllUsers,

        [Parameter(ParameterSetName='ExecuteChange', Mandatory=$false)]
        [switch] $ExecuteChange = $false

	)

    # Indicate whether this is a drift detection run or a deployment run
    if (-Not ($ExecuteChange)) {
        Write-Host "Current: Drift Detection Run"
    } else {
        Write-Host "Current: Deployment Run"
    }

    # Evaluate if group creation group exists. If it does not exist and it is not a drift detection run, create the group.
    $GroupCreationAllowedGroupId = New-GroupCreatorsGroup
    if((!$GroupCreationAllowedGroupId) -and ($ExecuteChange))
    {
        Write-Host "WARNING: Creation of the group creation group failed. Halting execution."
        return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
    }

    # Retrieve existing settings and template
    $DirectorySettingTemplateObjectId = (Get-MgBetaDirectorySettingTemplate | Where-Object {$_.DisplayName -eq "Group.Unified"}).id
    $DirectorySettingObjectId = (Get-MgBetaDirectorySetting | Where-Object {$_.DisplayName -eq "Group.Unified"}).id
    
    # Store desired settings in a params variable
    $params = @{
        templateId = $DirectorySettingTemplateObjectId
        values = @(
            @{
                name = "EnableGroupCreation"
                value = $EnableGroupCreationForAllUsers
            }
            @{
                name = "GroupCreationAllowedGroupId"
                value = $GroupCreationAllowedGroupId
            }
        )
    }

    # Evaluate drift from the desired configuration
    Write-Host "Now evaluating drift between current and desired state."
    $PreResults = Compare-GroupCreatorsGroup
    $Iteration = $PreResults["Iteration"]
    $DriftCounter = $PreResults["DriftCounter"]
    $ReturnCode = $PreResults["ReturnCode"]
    $DriftSummary = $PreResults["DriftSummary"]

    if($ReturnCode -eq 1)
    {
        return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
    }

    # If this is a drift detection run, end the function
    if (-Not ($ExecuteChange)) 
    {
        Write-Host "This is a drift detection run. No changes will be made."
        if($DriftCounter -gt 0)
        {
            return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
        }
        else
        {
            return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
        }
    }
    else
    {
        # Execute the change if there is drift detected
        if($DriftCounter -gt 0)
        {
            Write-Host "-----------------------------------------------------------------------------------------------------"
            if (!$DirectorySettingObjectId)
            {
                $PauseDuration = 2
                Write-Host "Now creating missing Directory Group Creation settings object."
                $DirectorySettingObjectId = (New-MgBetaDirectorySetting -BodyParameter $params).Id
                Write-Host "Now pausing for $PauseDuration seconds to give the new Directory Group Creation settings object time to replicate."
                Start-Sleep -Seconds $PauseDuration
            }
            else
            {
                Write-Host "Now updating Directory Group Creation settings object with desired settings."
                $HideOutput = Update-MgBetaDirectorySetting -DirectorySettingId $DirectorySettingObjectId -BodyParameter $params
            }
            Write-Host "Now performing post-configuration checks for Directory Group Creation settings object."
            Write-Host "-----------------------------------------------------------------------------------------------------"
            
            # Evaluate drift from the desired configuration
            $PostResults = Compare-GroupCreatorsGroup
			$DriftCounter = $PostResults["DriftCounter"]
			$DriftSummary = $PostResults["DriftSummary"]

            if($DriftCounter -eq 0)
			{
				Write-Host "Settings are configured as desired. The change was successful."
				return Get-ReturnValue -ExitCode 3 -DriftSummary $DriftSummary
			}
			else
			{
				Write-Host "WARNING: Settings did not pass post-execution checks. The change was not successful."
				return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
			}
		}
		elseif ($DriftCounter -eq 0)
		{
			Write-Host "No change is required. Settings are already configured as desired."
			return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
		}
		else
		{
			Write-Host "WARNING: Unable to complete post-execution validation."
			return Get-ReturnValue -ExitCode 1 -DriftSummary $DriftSummary
		}
	}
}