function New-ParameterList {
    param (
        [Parameter (Mandatory = $true)]
        [string[]] $VariableList
    )

    $ParameterList = @{}
    foreach ($Variable in $VariableList)
    {
        $VariableValue = Get-Variable -Name $Variable -ValueOnly -ErrorAction SilentlyContinue
        if ($VariableValue)
        {
            $ParameterList[$Variable] = $VariableValue
        }
    }
    return $ParameterList
}