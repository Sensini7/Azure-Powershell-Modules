@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'EntraIdUserPasswordPolicyConfig.psm1'

    # Version number of this module.
    ModuleVersion = '1.0'

    # ID used to uniquely identify this module
    GUID = '0d8fb5c4-8c0c-4d90-abdb-44528d3d5d73'

    # Author of this module
    Author = 'Noah'

    # Company or vendor of this module
    CompanyName = 'Easy Dynamics Co.'

    # Copyright statement for this module
    Copyright = '(c) 2024 Easy Dynamics Co. All rights reserved.'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{
            ModuleName = "Microsoft.Graph.Identity.DirectoryManagement"
            ModuleVersion = "2.24.0"
        },
        @{
            ModuleName = "CommonModuleName"
            ModuleVersion = "1.0.0"
        }
    )

    # Functions to export from this module
    FunctionsToExport = @('Compare-DomainPasswordPolicy', 'Set-DomainPasswordPolicy')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData = @{
        PSData = @{
            # Additional metadata and settings
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PasswordPolicy', 'AzureAD', 'Automation', 'Security')

            # A URL to the license for this module.
            LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = ''

            # A URL to an icon representing this module.
            IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of the password policy management module.'

            # Prerelease string of this module
            Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false

            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    DefaultCommandPrefix = ''
}