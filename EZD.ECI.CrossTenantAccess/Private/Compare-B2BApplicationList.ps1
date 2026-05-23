function Compare-B2BApplicationList {
    param (
        [Parameter(Mandatory=$true)]
        $CurrentApplicationList,

        [Parameter(Mandatory=$true)]
        $DesiredApplicationList
	)

    $CombinedMissingApplicationList = @()

    # Determine if any settings in the current application list are not in the desired list and should be removed
    $RemoveApplicationList = @()
    foreach($Application in $CurrentApplicationList)
    {
        $ApplicationName = $Application.target
        if($DesiredApplicationList.target -NotContains $ApplicationName)
        {
            $RemoveApplicationList += $ApplicationName
            $DriftCounter += 1
        }
    }
    if($RemoveApplicationList.Count -gt 0)
    {
        Write-Host "`tThe following applications are present in the current application list but are not in the desired application list. They should be removed."
        $RemoveApplicationList | foreach { Write-Host "`t`t"$_ }
        $CombinedMissingApplicationList += $RemoveApplicationList
    }
    else
    {
        Write-Host "`tThere are no applications present in the current application list which are not present in the desired application list."
    }
    
    # Determine if any settings in the desired application list are not in the current list and should be added
    $AddApplicationList = @()
    foreach($Application in $DesiredApplicationList)
    {
        $ApplicationName = $Application.target
        if($CurrentApplicationList.target -NotContains $ApplicationName)
        {
            $AddApplicationList += $ApplicationName
            $DriftCounter += 1
        }
    }
    if($AddApplicationList.Count -gt 0)
    {
        Write-Host "`tThe following applications are present in the desired application list but are not in the current application list. They should be added."
        $AddApplicationList | foreach { Write-Host "`t`t"$_ }
        $CombinedMissingApplicationList += $AddApplicationList
    }
    else
    {
        Write-Host "`tThere are no applications present in the desired application list which are not present in the current application list."
    }

    # Display a log message if there are no misconfigured applications
    if($CombinedMissingApplicationList.Count -eq 0)
    {
        Write-Host "`tApplications are configured as expected. No change is necessary."
    }

    return @{ "DriftCounter" = $DriftCounter; "RemoveApplicationList" = $RemoveApplicationList; "AddApplicationList" = $AddApplicationList }
}