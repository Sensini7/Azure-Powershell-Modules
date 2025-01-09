@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'EZD.ECI.PIMSettings.psm1'

    # Version number of this module.
    ModuleVersion = '1.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-1234567890ab'

    # Author of this module
    Author = 'Noah @Easy Dynamics Corporation'

    # Company or vendor of this module
    CompanyName = 'Easy Dynamics Co.'

    # Copyright statement for this module
    Copyright = '(c) 2024 Easy Dynamics Co. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module to configure Azure PIM settings to meet SCUBA requirements 7.6, 7.7, 7.8, and 7.9'

    # Minimum version of the Windows PowerShell engine required by this module
    #PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{
            ModuleName = "Microsoft.Graph.Identity.SignIns";
            ModuleVersion = "2.25.0"
        },
        @{
            ModuleName = "EZD.ECI.Common";
            ModuleVersion = "1.0"
        }
    )

    # Functions to export from this module
    FunctionsToExport = @('Compare-PIMSettings', 'Set-PIMSettings')

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
            Tags = @('PIM', 'AzureAD', 'Automation', 'Security', 'SCUBA')

            # A URL to the license for this module.
            LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = ''

            # A URL to an icon representing this module.
            IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of the PIM settings management module.'

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
