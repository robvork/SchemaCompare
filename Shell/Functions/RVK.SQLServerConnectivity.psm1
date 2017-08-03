$DefaultConnectionTimeout = 3

function Test-SQLServerInstance
{
    [CmdletBinding()]
    param
    (
        [String] 
        $ServerInstance

    ,   [Int]
        $ConnectionTimeout = $DefaultConnectionTimeout
    )

    try
    {
        Ping-SQLServerDatabase $ServerInstance -Database master -ConnectionTimeout $ConnectionTimeout
        $ServerInstanceValid = $true 
    }
    catch
    {
        $ServerInstanceValid = $false 
    }

    return $ServerInstanceValid
}

function Test-SQLServerDatabase
{
    [CmdletBinding()]
    param
    (
        [String] 
        $ServerInstance

    ,   [String]
        $Database
    
    ,   [Int]
        $ConnectionTimeout = $DefaultConnectionTimeout
    )
    
    $ServerInstanceValid = Test-SQLServerInstance -ServerInstance $ServerInstance -ConnectionTimeout $ConnectionTimeout
    if(-not $ServerInstanceValid)
    {
        return $false; 
    }

    try
    {
        Ping-SQLServerDatabase -ServerInstance $ServerInstance -Database $Database -ConnectionTimeout $ConnectionTimeout
        $DatabaseValid = $true 
    }
    catch
    {
        $DatabaseValid = $false 
    }

    return $DatabaseValid 
}

function Ping-SQLServerDatabase
{
    [CmdletBinding()]
    param
    (
        [String]
        $ServerInstance 
    ,
        [String]
        $Database
    ,
        [Int]
        $ConnectionTimeout = $DefaultConnectionTimeout
    )

    try
    {
        $connString = @("Server=$ServerInstance","Database=$Database", "Timeout=$ConnectionTimeout", "Trusted_Connection=True") -join ";"
        $conn = [System.Data.SqlClient.SqlConnection]$connString
        $conn.Open()
        $conn.Close()
    }
    catch
    {
        throw 'Ping failed' 
    }
}


Export-ModuleMember Test-SQLServerInstance
Export-ModuleMember Test-SQLServerDatabase 
