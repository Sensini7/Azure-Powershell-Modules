function ConvertTo-HashTable {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    if (!$InputObject) {
        return $null
    } elseif ($InputObject.GetType().Name -eq "PSCustomObject") {
        $hashTable = @{}
        $InputObject.PSObject.Properties | ForEach-Object {
            $hashTable[$_.Name] = $_.Value
        }
        return $hashTable
    } elseif ($InputObject.GetType().Name -eq "Object[]") {
        $list = @()
        ForEach ($item in $InputObject) {
            $list += ConvertTo-HashTable -InputObject $item
        }
        return $list
    } else {
        throw "Could not convert object to hashtable"
        return $InputObject
    }
}