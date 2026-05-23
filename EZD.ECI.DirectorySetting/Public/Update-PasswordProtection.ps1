function Update-PasswordProtection {

	param (
		
		[Parameter(Mandatory = $false)]
		[string] $BannedPasswordCheckOnPremisesMode,

		[Parameter(Mandatory = $false)]
		[string] $EnableBannedPasswordCheckOnPremises,

		[Parameter(Mandatory = $false)]
		[string] $EnableBannedPasswordCheck,

		[Parameter(Mandatory = $false)]
		[string] $LockoutDurationInSeconds,

		[Parameter(Mandatory = $false)]
		[string] $LockoutThreshold,

		[Parameter(Mandatory = $false)]
		[String[]] $BannedPasswordList,

        [Parameter(Mandatory=$true)]
        [switch] $ExecuteChange  

	)

	# Retrieve the id of the password rule settings object
	## $id = 7e4e7ff1-d663-4ee6-88d6-41252ab886ce
	$id = (Get-MgBetaDirectorySetting | Where-Object { $_.DisplayName -eq "Password Rule Settings" }).id
	if(!$id)
	{
		$TemplateId = (Get-MgBetaDirectorySettingTemplate | Where-Object { $_.DisplayName -eq "Password Rule Settings" }).Id
	}

	# Compile desired settings
	## Split on commas and trim whitespace
	$PasswordListSplit = $BannedPasswordList.Split(",").Trim()
	$PasswordListSplit = $PasswordListSplit | Where-Object { $_.Length -le 16 -and $_.Length -ge 4 }

	## Join with newlines inbetween to create a 
	$PasswordNewLineDelimitedList = $PasswordListSplit -join "`r`n"

	# Build params object
	$params = @{
		values = @(
			@{
				name = "BannedPasswordCheckOnPremisesMode"
				value = $BannedPasswordCheckOnPremisesMode
			},
			@{
				name = "EnableBannedPasswordCheckOnPremises"
				value = $EnableBannedPasswordCheckOnPremises
			},
			@{
				name = "EnableBannedPasswordCheck"
				value = $EnableBannedPasswordCheck
			},
			@{
				name = "LockoutDurationInSeconds"
				value = $LockoutDurationInSeconds
			},
			@{
				name = "LockoutThreshold"
				value = $LockoutThreshold
			},
			@{
				name = "BannedPasswordList"
				value = $PasswordNewLineDelimitedList
			}
		)
	}

	# Validate alignment of the current state and the desired state
	$PreResults = Compare-PasswordProtection
	$Iteration = $PreResults["Iteration"]
	$DriftCounter = $PreResults["DriftCounter"]
	$DriftSummary = $PreResults["DriftSummary"]

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
			if(!$id)
			{
                Write-Host "TemplateId is $TemplateId"
				$params["templateId"] = $TemplateId
				Write-Host "Now deploying new password rule policy object with desired settings."
				$HideOutput = New-MgBetaDirectorySetting -BodyParameter $params
			}
			else
			{
				Write-Host "Now deploying desired configuration to password rule settings."
				$HideOutput = Update-MgBetaDirectorySetting -DirectorySettingId $id -BodyParameter $params
			}
			Write-Host "Now performing post-configuration checks for password rule settings."			
			Write-Host "-----------------------------------------------------------------------------------------------------"

			# Evaluate drift from the desired configuration
			$PostResults = Compare-PasswordProtection
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