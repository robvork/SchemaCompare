function Initialize-SchemaCompareIDGenerator
{
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   [String] $Database
    )

    $Query = "EXECUTE [config].[p_initialize_next_id]"
    Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query 
}

function Initialize-SchemaCompareObjectClass
{
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   [String] $Database
    )
    $Query = "EXECUTE [config].[p_initialize_object_class]"
    Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query 
}

function Initialize-SchemaCompareObjectToSubobject
{
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   [String] $Database
    )
    $Query = "EXECUTE [config].[p_initialize_object_to_subobject]"
    Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query 
}

function Initialize-SchemaCompareSystemType
{
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   [String] $Database
    )
    $Query = "EXECUTE [config].[p_initialize_system_type]"
    Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query 
}

function Initialize-SchemaCompareSystemView 
{
    
}

function Initialize-SchemaCompareObjectClassProperty
{
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   [String] $Database
    )
    $Query = "EXECUTE [config].[p_initialize_object_class_property]"
    Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query 
}