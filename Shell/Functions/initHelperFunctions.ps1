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
                                @{n="object_class_source"; e={"'" + ($_.source.Trim() -replace "(?<!')'(?!')", "''")  + "'"}},
                                @{n="object_class_source_alias"; e={"'" + $_.source_alias.Trim() + "'"}},
                                @{n="view_schema_name"; e={"'" + $_.view_schema_name.Trim() + "'"}},
                                @{n="view_name"; e={"'" + $_.view_name.Trim() + "'"}} |
                # Combine properties into one string separated by a comma, then a line break
                ForEach-Object { @( $_.object_class_name
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
                                                # by a comma, then a line break
                
    $ColumnList = @(
                        "object_class_name"
                        "object_class_source"
                        "object_class_source_alias"
                        "view_schema_name"
                        "view_name"
                ) -join ",`n"
    $InputTableName = "#object_class_input"
    $InsertHeader = @(
                        "INSERT INTO ${InputTableName}"
                        "("
                            $ColumnList
                        ")"
                        "VALUES"
                    ) -join "`n"

    $InsertSQL = @(
                    $InsertHeader 
                    $RowSet
                ) -join "`n"
                    
    
    $Query = "
            DROP TABLE IF EXISTS ${InputTableName};

            CREATE TABLE ${InputTableName}
            (
                object_class_name NVARCHAR(128) NOT NULL
            ,   object_class_source NVARCHAR(MAX) NOT NULL
            ,   object_class_source_alias NVARCHAR(10) NOT NULL
            ,   view_schema_name SYSNAME NOT NULL
            ,   view_name SYSNAME NOT NULL
            );

            $InsertSQL ;
    
            EXECUTE [config].[p_initialize_object_class]
                      @as_input_table_name = '$InputTableName' 
             "
    Write-Verbose "Executing the following SQL query:`n $Query"
    Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query 
}

function Initialize-SchemaCompareObjectClassToSubobjectClass
{
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   [String] $Database
    ,   [String] $ConfigFilePath
    )

    $ObjectSubobjectClassMap = ([xml] (Get-Content -Path $ConfigFilePath -Raw)).ClassMappings.ClassMapping

    $RowSet =  ($ObjectSubobjectClassMap |
                # Add quotes, trim whitespace
                Select-Object   @{n="object_class_name"; e={"'" + $_.objectClassName.Trim() + "'"}}, 
                                @{n="subobject_class_name"; e={"'" + $_.subobjectClassName.Trim() + "'"}},
                                @{n="name_query"; e={"'" + ($_.nameQuery.Trim() -replace "(?<!')'(?!')", "''") + "'"}} | 
                # Combine properties into one string separated by a comma, then a line break
                ForEach-Object { @( $_.object_class_name
                                    $_.subobject_class_name
                                    $_.name_query
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
                                                # by a comma, then a line break
                
    $ColumnList = @(
                        "object_class_name"
                        "subobject_class_name"
                        "name_query"
                ) -join ",`n"
    $InputTableName = "#object_to_subobject_input"
    $InsertHeader = @(
                        "INSERT INTO ${InputTableName}"
                        "("
                            $ColumnList
                        ")"
                        "VALUES"
                    ) -join "`n"

    $InsertSQL = @(
                    $InsertHeader 
                    $RowSet
                ) -join "`n"

    $Query = "
            DROP TABLE IF EXISTS ${InputTableName};

            CREATE TABLE ${InputTableName}
            (
                object_class_name NVARCHAR(128) NOT NULL
            ,   subobject_class_name NVARCHAR(128) NOT NULL
            ,   name_query NVARCHAR(MAX) NOT NULL
            );

            $InsertSQL ;
    
    EXECUTE [config].[p_initialize_object_to_subobject]
                @as_input_table_name = '$InputTableName'"
    Write-Verbose "Executing the following SQL query:`n $Query"
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
