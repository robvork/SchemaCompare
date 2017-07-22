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
    ,   [String] $ConfigFilePath
    )

    $ObjectClasses = ([xml](Get-Content $ConfigFilePath -Raw)).ObjectClasses.ObjectClass 

$RowSet =  ($ObjectClasses |
              # Add quotes, trim whitespace, match name with table column name 
              Select-Object   @{n="object_class_name"; e={"'" + $_.name.Trim() + "'"}}, 
                              @{n="object_class_source"; e={"'" + $_.source.Trim() + "'"}},
                              @{n="object_class_source_alias"; e={"'" + $_.source_alias.Trim() + "'"}},
                              @{n="view_schema_name"; e={"'" + $_.view_schema.Trim() + "'"}},
                              @{n="view_name"; e={"'" + $_.view_name.Trim() + "'"}} |
              # Combine properties into one string separated by a comma, then a line break
              ForEach-Object { @($_.object_class_name
                                 $_.object_class_source 
                                 $_.object_class_source_alias
                                 $_.view_schema_name
                                 $_.view_name
                                ) -join ",`n"
                             } | 
              # Enclose each row with ( and )
              ForEach-Object {
                               @( 
                                    "(" 
                                     $_
                                    ")"
                                ) -join "`n"
                             }) -join ",`n" # combine all rows into one string, separating
                                            # by a comma, then a newline
             
$ColumnList = @(
                    "object_class_name"
                    "object_class_source"
                    "object_class_source_alias"
                    "view_schema_name"
                    "view_name"
               ) -join ",`n"
$InsertHeader = @(
                    "INSERT INTO [config].[object_class]"
                    "("
                        $ColumnList
                    ")"
                    "VALUES"
                 ) -join "`n"

$InsertSQL = @(
                $InsertHeader 
                $RowSet
              ) -join "`n"
echo $InsertSQL 
                    
                    

                     

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
    ,   [String] $ConfigFilePath
    )
    $Query = "EXECUTE [config].[p_initialize_object_to_subobject]"
    Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query 
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