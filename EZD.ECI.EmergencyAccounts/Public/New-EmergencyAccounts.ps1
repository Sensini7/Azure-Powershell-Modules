function New-EmergencyAccounts {
# reqs params: user principal name, display name, vault name
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $false)]
        [ValidateRange(8, [int]::MaxValue)]
        [int]$PasswordLength = 24,

        [Parameter(Mandatory = $false)]
        [string]$ExpireDays = 90, # The key automatically expires in 90 days (since AC-2(2) says it must be rotated every 90 days)

        [Parameter(Mandatory = $true)]
        [string]$VaultName,
        
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultSecretName,
        
        [Parameter(Mandatory = $false)]
        [switch]$AssignGlobalAdmin = $false
    )
    $ErrorActionPreference = "Continue" #"Stop"

    $Group = (Get-MgGroup -Filter "displayName eq 'Emergency Access Group'")
    if ($Group) {
        $GroupId = $Group.Id
    } else {
        throw "Error: Emergency group doesn't exist. Terraform didn't properly create it"
    }

    $UpperCase = [char[]](65..90)
    $LowerCase = [char[]](97..122)
    $Nums      = [char[]](48..57)
    $Special   = [char[]](33, 42, 46)
    $Chars = [char[]]($UpperCase + $LowerCase + $Nums + $Special)

    $ReqChars = @(
        Get-Random -Count 1 -InputObject $UpperCase
        Get-Random -Count 1 -InputObject $LowerCase
        Get-Random -Count 1 -InputObject $Nums
        Get-Random -Count 1 -InputObject $Special
    )

    $Password = -join (Get-Random -Count $PasswordLength ((Get-Random -Count ($PasswordLength - 4) -InputObject $Chars) + $ReqChars))

    $PasswordProfile = @{
        Password = $Password
        ForceChangePasswordNextSignIn = $false
        ForceChangePasswordNextSignInWithMfa = $false
    }

    $StrippedDisplayName = $DisplayName -replace '\s',''

    $ReturnValue = 0

    try {
        # checking if needing to create user
        $BreakglassUser = Get-MgUser -ConsistencyLevel eventual -Count userCount -Search "UserPrincipalName:$UserPrincipalName"
        if ($BreakglassUser) {
            Write-Host "$DisplayName already exists"

        } else {
            $BreakglassUser = New-MgUser -DisplayName $DisplayName -PasswordProfile $PasswordProfile -AccountEnabled -UserPrincipalName $UserPrincipalName -MailNickname $StrippedDisplayName
            if (Get-MgUser -UserId $BreakglassUser.Id) {
                Write-Host "Success: Created new user $DisplayName"

                # Cast password to a secure str
                $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

                # set the secret in SecretName to have the value of the password
                Set-AzKeyVaultSecret -VaultName $VaultName -Name $KeyVaultSecretName -SecretValue $SecurePassword
                Write-Host "Success: Assigned password to secret in $VaultName"
                $ReturnValue = 2
            } else {
                throw "Error: User not created. Can't continue."

            }
        }


        if ($AssignGlobalAdmin -eq $false) {
            Write-Host "Skipping Global Administrator assignment (AssignGlobalAdmin = $AssignGlobalAdmin)"
            Write-Warning "Global Administrator must be assigned to the Emergency Accounts manually. This is done to limit the privilege of the service principal executing this script."
        } else {
            $Role = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq "Global Administrator" }
            $RoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $Role.Id
            
            if ($RoleMembers.Id -contains $BreakglassUser.Id){
                Write-Host "Success: User is already a Global Administrator"
            } else {
                $assignRole = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($BreakglassUser.Id)" }
                New-MgDirectoryRoleMemberByRef -DirectoryRoleId $Role.Id -BodyParameter $assignRole
                Write-Host "Success: Assigned new user $DisplayName Global Administrator"
                $ReturnValue = 2
            }
        }

        $GroupMembers = Get-MgGroupMember -GroupId $GroupId 
        if ($GroupMembers.Id -contains $BreakglassUser.Id) {
            Write-Host "Success: User is already in Emergency Access Group"
        } else {
            # add them to a the emergency group 
            New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $BreakglassUser.Id
            Write-Host "Success: Assigned new user $DisplayName to Emergency Access Group"
            $ReturnValue = 2
        }
        
        return $ReturnValue
        
    }
    catch {
        Write-Host "Error: Exception in API Call: $($_.Exception.Message)"
        return 1
    }
}