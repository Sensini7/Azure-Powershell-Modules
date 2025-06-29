function Connect-EciGraph {
    Param (
        [switch] $ConnectSubscription = $false,
        [string] $DriftScriptPath = ".\Compare-DriftResult.ps1",
        [switch] $UseOIDC = $false
    )

    $EnvVars = @(
        "AZURE_CLIENT_ID",
        "AZURE_TENANT_ID",
        "IS_AZURE_GOV"
    )
    if (-not $UseOIDC) {
        $EnvVars += "AZURE_CLIENT_SECRET"
    }
    if ($ConnectSubscription) {
        $EnvVars += "AZURE_SUBSCRIPTION_ID"

        ## Since the Az.Accounts module is only needed if ConnectSubscription is specified, we do not explicitly require it for the
        ## RequiredModules section in the module manifest. Instead, we check for its presence here.
        if (-Not (Get-Module Az.Accounts)) {
            Write-Error "Az.Accounts module is not imported. Please import it before running this script."
            Exit 1
        }
    }

    $ErrorCount = 0
    ForEach ($EnvVar in $EnvVars) {
        if (-not (Get-Item env:$EnvVar -ErrorAction SilentlyContinue)) {
            Write-Error "Environment variable $EnvVar is not set. Please set it before running this script."
            $ErrorCount += 1
        }
    }

    if ($ErrorCount -gt 0) {
        Write-Output "Required env vars: "
        $EnvVars 
        Write-Error "Please set the required environment variables before running this script."
        Exit 1
    }

    if ($env:IS_AZURE_GOV -eq "true") {
        $ARM_ENVIRONMENT = 'AzureUSGovernment'
        $GRAPH_ENVIRONMENT = 'USGov'
        $GRAPH_API_BASE_URL = "https://graph.microsoft.us"
    } else {
        $ARM_ENVIRONMENT = 'AzureCloud'
        $GRAPH_ENVIRONMENT = 'Global'
        $GRAPH_API_BASE_URL = "https://graph.microsoft.com"
    }

    ## Only necessary when using GitHub 
    if ($env:GITHUB_SERVER_URL -And (-Not (Get-Module -ListAvailable "Az.Accounts" -ErrorAction SilentlyContinue))) {
        Install-Module -Name Az.Accounts -Force
    }

    while (Get-MgContext -ErrorAction SilentlyContinue) {
        Disconnect-MgGraph
    }

    # Only log out if not using OIDC
    if (-not $UseOIDC) {
        while ($(az account show)) {
            az logout
        }
    } else {
        # When using OIDC, just verify we have an active session
        $azAccount = az account show
        if (-not $azAccount) {
            Write-Error "No active Azure CLI session found. OIDC authentication may have failed."
            exit 1
        }
        Write-Output "Using existing Azure CLI authentication from OIDC"
    }
    while (Get-AzContext -ErrorAction SilentlyContinue) {
        Disconnect-AzAccount
    }

    try {
        az cloud set --name $ARM_ENVIRONMENT

        if ($UseOIDC) {
            Write-Output "Using OIDC authentication..."
            # OIDC auth already handled by prior login (e.g., azure/login@v2 in GitHub Actions)
            $AccessToken = (az account get-access-token --resource-type ms-graph | ConvertFrom-Json).accessToken 
        } else {
            Write-Output "Using Client Secret authentication..."
            $azLoginResponse = az login --service-principal -u $env:AZURE_CLIENT_ID -p $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID
            if (-Not ($azLoginResponse)) {
                $ErrorMessage = "An error occurred while connecting to Microsoft Graph"
                if ($env:RUN_DRIFT_DETECTION -eq 'true') {
                    $Result = Get-ReturnValue -ExitCode 2 -DriftSummary $ErrorMessage
                    & $DriftScriptPath -DriftType PS -ResultObjects $Result
                    exit 2
                } else {
                    Write-Warning $ErrorMessage
                }
            }
            $AccessToken = (az account get-access-token --resource-type ms-graph | ConvertFrom-Json).accessToken
        }

        Write-Output "Connecting to MgGraph..."
        # Use SecureString for compatibility with original structure
        $SecureAccessToken = ConvertTo-SecureString -String $AccessToken -AsPlainText -Force
        Connect-MgGraph -AccessToken $SecureAccessToken -NoWelcome -Environment $GRAPH_ENVIRONMENT
    } catch {
      $ErrorMessage = "An error occurred while connecting to Microsoft Graph"
      if ($env:RUN_DRIFT_DETECTION -eq 'true') {
        $Result = Get-ReturnValue -ExitCode 2 -DriftSummary $ErrorMessage
        & $DriftScriptPath -DriftType PS -ResultObjects $ErrorMessage
      }
      Write-Error $ErrorMessage
      exit 1
    }

    # Capture tenant context in the logs
    $CurrentTenant = Invoke-MgGraphRequest -Method GET -Uri "$GRAPH_API_BASE_URL/v1.0/organization"
    $CurrentTenantName = $CurrentTenant.value[0].displayName
    Write-Output "You are in the $CurrentTenantName tenant"

    if ($ConnectSubscription) {
        try {
            if ($UseOIDC) {
                if ($env:AZURE_SUBSCRIPTION_ID) {
                    Write-Output "Selecting subscription: $env:AZURE_SUBSCRIPTION_ID"
                    Select-AzSubscription -SubscriptionId $env:AZURE_SUBSCRIPTION_ID
                }
            } else {
                $SecureStringClientSecret = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential ($env:AZURE_CLIENT_ID, $SecureStringClientSecret)
                $HideOutput = Connect-AzAccount -Environment $ARM_ENVIRONMENT -SubscriptionId $env:AZURE_SUBSCRIPTION_ID -TenantId $env:AZURE_TENANT_ID -Credential $Credential -ServicePrincipal
                if (-Not (Get-AzContext)) {
                    $ErrorMessage = "An error occurred while connecting to Microsoft Graph"
                    if ($env:RUN_DRIFT_DETECTION -eq 'true') {
                        $Result = Get-ReturnValue -ExitCode 2 -DriftSummary $ErrorMessage
                        & $DriftScriptPath -DriftType PS -ResultObjects $Result
                        exit 2
                    } else {
                        Write-Warning $ErrorMessage
                    }
                }
            }
        } catch {
            $ErrorMessage = "An error occurred while connecting to Azure RM"
            if ($env:RUN_DRIFT_DETECTION -eq 'true') {
                $Result = Get-ReturnValue -ExitCode 2 -DriftSummary $ErrorMessage
                & $DriftScriptPath -DriftType PS -ResultObjects $Result
                exit 2
            }
            Write-Warning $ErrorMessage
            exit 1
        }
    }
}
