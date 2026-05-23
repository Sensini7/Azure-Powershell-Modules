function Get-StandardAuthMethodParameters {

    # Define allowed data types
    $DataType = @{
        "Email"                  = "#microsoft.graph.emailAuthenticationMethodConfiguration"
        "Fido2"                  = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
        "MicrosoftAuthenticator" = "#microsoft.graph.emailAuthenticationMethodConfiguration"
        "Sms"                    = "#microsoft.graph.smsAuthenticationMethodConfiguration"
        "SoftwareOath"           = "#microsoft.graph.softwareOathAuthenticationMethodConfiguration"
        "TemporaryAccessPass"    = "#microsoft.graph.temporaryAccessPassAuthenticationMethodConfiguration"
        "Voice"                  = "#microsoft.graph.voiceAuthenticationMethodConfiguration"
        "X509Certificate"        = "#microsoft.graph.x509CertificateAuthenticationMethodConfiguration"
    }

    # Compile desired include targets
    if(!$IncludeTargets)
    {
        Write-Host "No include targets were specified. Setting include targets to include all_users."
        $IncludeTargets = @( @{ targetType = "group"; id = "all_users"; isRegistrationRequired = $false } )
    }
    else {
        Write-Host "Now compiling desired include targets."        
    }
    
    # Determine desired authentication method state
    if ($EnabledMethods -contains $CurrentMethod) {
        $ParamState = "enabled"
    } elseif ($DisabledMethods -contains $CurrentMethod)
    {
        $ParamState = "disabled"
    }
    
    # Compile parameters object for setting the desired configuration
    $params = @{
        "@odata.type"                   = $DataType[$CurrentMethod]
        state                           = $ParamState
        includeTargets                  = $IncludeTargets
        id                              = $CurrentMethod
    }

    return $params

}