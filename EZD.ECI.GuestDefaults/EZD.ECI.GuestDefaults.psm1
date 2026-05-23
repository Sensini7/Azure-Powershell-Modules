# Get all the .ps1 files in the public directory
$PublicFunctions = Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue

# Get all the .ps1 files in the private directory
$PrivateFunctions = Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue

$AllFunctions = @()

# Combine public and private functions
$AllFunctions += $PublicFunctions
$AllFunctions += $PrivateFunctions 

# Dot-source the files
foreach ($File in $AllFunctions) {
    . $File.FullName
}

# Get the names of all the functions that were just sourced
$ExportedFunctions = Get-Command -CommandType Function | 
                     Where-Object { $_.ScriptBlock.File -in $AllFunctions.FullName } | 
                     ForEach-Object { $_.Name }

# Export the functions
Export-ModuleMember -Function $ExportedFunctions