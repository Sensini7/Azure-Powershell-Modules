function Get-StandardAuthMethodPrechecks {

    # Declare whether the workflow is running in drift detection or configuration mode
    Write-Host "----------------------------------------------------------------------------------------------------"
    Write-Host "Now initiating pre-checks for authentication method $CurrentMethod."

    $DataType = @{
        "Fido2"                  = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
        "MicrosoftAuthenticator" = "#microsoft.graph.emailAuthenticationMethodConfiguration"
        "Sms"                    = "#microsoft.graph.smsAuthenticationMethodConfiguration"
        "TemporaryAccessPass"    = "#microsoft.graph.temporaryAccessPassAuthenticationMethodConfiguration"
        "SoftwareOath"           = "#microsoft.graph.softwareOathAuthenticationMethodConfiguration"
        "Email"                  = "#microsoft.graph.emailAuthenticationMethodConfiguration"
        "X509Certificate"        = "#microsoft.graph.x509CertificateAuthenticationMethodConfiguration"
        "Voice"                  = "#microsoft.graph.voiceAuthenticationMethodConfiguration"
    }

    # Check if the specified methods are all valid authentication methods
    if (-Not $DataType.ContainsKey($CurrentMethod)) {
        Write-Host "WARNING: $CurrentMethod is not a valid Authentication Method. Please correctly specify methods in the following way: $($DataType.Keys)."
        return 1
    }
    else
    {
        Write-Host "Current method $CurrentMethod is a valid authentication method in the authentication method reference table. This is expected. Proceeding."
    }

    # Check if a method is both in Enabled and Disabled
    $intersection = Compare-Object -ReferenceObject $EnabledMethods -DifferenceObject $DisabledMethods -ExcludeDifferent -IncludeEqual
    if ($intersection.InputObject.Count -gt 0) {
        Write-Host "WARNING: The following method(s) has been specified in both Enabled and Disabled methods. Please have all methods be uniquely enabled/disabled. Method(s) = $($intersection.InputObject)"
        return 1
    }

    # Check if authentication method state is defined
    if(($EnabledMethods + $DisabledMethods) -NotContains $CurrentMethod)
    {
        Write-Host "WARNING: Desired state (Enabled / Disabled) is not defined for $CurrentMethod authentication method. Stopping execution. Please define desired state before re-running."
        return 1
    }
    else
    {
        Write-Host "Desired state is explicitly defined. Desired state is $ParamState. This is expected. Proceeding."
    }
}