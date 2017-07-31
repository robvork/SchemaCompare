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

    # Define the rows to be inserted to each table
    #   [config].[object_class] rows
    $ObjectClassRowSet =  (
                $ObjectClasses |
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
    #   [config].[object_class_metadata_key] rows                                               
    $MetadataKeyRowSet =  (
                $ObjectClasses |
                Select-Object name, 
                              @{n="metadata_keys"; e={$_.metadata_keys.metadata_key}} | 
                # Add quotes, trim whitespace, match name with table column name 
                ForEach-Object { 
                    $ObjectClassName = $_.Name
                    $_.metadata_keys | 
                    Select-Object @{n="object_class_name"; e={$ObjectClassName}},
                                  @{n="metadata_key_column_name"; e={$_.name}},
                                  @{n="metadata_key_column_type"; e={$_.type}},
                                  @{n="metadata_key_column_source"; e={$_.column}}
                } | 
                Select-Object   @{n="object_class_name"; e={"'" + $_.object_class_name.Trim() + "'"}}, 
                                @{n="metadata_key_column_name"; e={"'" + $_.metadata_key_column_name.Trim() + "'"}},
                                @{n="metadata_key_column_type"; e={"'" + $_.metadata_key_column_type.Trim() + "'"}},
                                @{n="metadata_key_column_source"; e={"'" + $_.metadata_key_column_source.Trim() + "'"}} | 
                # Combine properties into one string separated by a comma, then a line break
                ForEach-Object { @( $_.object_class_name
                                    $_.metadata_key_column_name
                                    $_.metadata_key_column_type
                                    $_.metadata_key_column_source
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
    
    #   [config].[object_class_object_key] rows
    $ObjectKeyRowSet = (	
                $ObjectClasses |
                Select-Object name, 
                              @{n="object_keys"; e={$_.object_keys.object_key}} | 
                # Add quotes, trim whitespace, match name with table column name 
                ForEach-Object { 
                    $ObjectClassName = $_.Name
                    $_.object_keys | 
                    Select-Object @{n="object_class_name"; e={$ObjectClassName}},
                                  @{n="object_key_column_name"; e={$_.name}},
                                  @{n="object_key_column_type"; e={$_.type}},
                                  @{n="object_key_column_source"; e={$_.column}}
                } | 
                Select-Object   @{n="object_class_name"; e={"'" + $_.object_class_name.Trim() + "'"}}, 
                                @{n="object_key_column_name"; e={"'" + $_.object_key_column_name.Trim() + "'"}},
                                @{n="object_key_column_type"; e={"'" + $_.object_key_column_type.Trim() + "'"}},
                                @{n="object_key_column_source"; e={"'" + $_.object_key_column_source.Trim() + "'"}} | 
                # Combine properties into one string separated by a comma, then a line break
                ForEach-Object { @( $_.object_class_name
                                    $_.object_key_column_name
                                    $_.object_key_column_type
                                    $_.object_key_column_source
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


    
    # Define the column list of each row set
    #   object class column list                                           
    $ObjectClassColumnList = @(
                        "object_class_name"
                        "object_class_source"
                        "object_class_source_alias"
                        "view_schema_name"
                        "view_name"
                             )     
    #   metadata class column list
    $MetadataKeyColumnList = @(
                        "object_class_name"
                        "metadata_key_column_name"
                        "metadata_key_column_type"
                        "metadata_key_column_source"
    )
    #   object key column list
    $ObjectKeyColumnList = @(
                        "object_class_name"
                        "object_key_column_name"
                        "object_key_column_type"
                        "object_key_column_source"
    )

    # Define the names of the input tables for each row set
    $ObjectClassInputTableName = "#object_class_input"
    $MetadataKeyInputTableName = "#metadata_keys_input"
    $ObjectKeyInputTableName = "#object_keys_input"

    # Define the insert headers for each input table
    $ObjectClassInsertHeader = @(
                        "INSERT INTO ${ObjectClassInputTableName}"
                        "("
                            ($ObjectClassColumnList -join "`n, ")
                        ")"
                        "VALUES"
                    ) -join "`n"

    $MetadataKeyInsertHeader = @(
                        "INSERT INTO ${MetadataKeyInputTableName}"
                        "("
                            ($MetadataKeyColumnList -join "`n, ")
                        ")"
                        "VALUES"
                    ) -join "`n"

    $ObjectKeyInsertHeader = @(
                        "INSERT INTO ${objectKeyInputTableName}"
                        "("
                            ($ObjectKeyColumnList -join "`n, ")
                        ")"
                        "VALUES"
                    ) -join "`n"

    # Define the full SQL statement for inserting the rowset into its respective input table
    $ObjectClassInsertSQL = @(
                    $ObjectClassInsertHeader 
                    $ObjectClassRowSet
                ) -join "`n"
    $MetadataKeyInsertSQL = @(
                    $MetadataKeyInsertHeader
                    $MetadataKeyRowSet
                ) -join "`n"
    $ObjectKeyInsertSQL = @(
                    $ObjectKeyInsertHeader
                    $ObjectKeyRowSet
                ) -join "`n"
                
    # Define the full query for creating and populating each input table and subsequently calling the SQL procedure for initializing object class and related tables
    $Query = "
            DROP TABLE IF EXISTS ${ObjectClassInputTableName};

            CREATE TABLE ${ObjectClassInputTableName}
            (
                object_class_name NVARCHAR(128) NOT NULL
            ,   object_class_source NVARCHAR(MAX) NOT NULL
            ,   object_class_source_alias NVARCHAR(10) NOT NULL
            ,   view_schema_name SYSNAME NOT NULL
            ,   view_name SYSNAME NOT NULL
            );

            DROP TABLE IF EXISTS ${MetadataKeyInputTableName};

            CREATE TABLE $MetadataKeyInputTableName
            (
                [object_class_name] SYSNAME NOT NULL
            ,	[metadata_key_column_name] SYSNAME
            ,	[metadata_key_column_type] SYSNAME
            ,	[metadata_key_column_source] SYSNAME
            ,	PRIMARY KEY
                (
                    [object_class_name]
                ,	[metadata_key_column_name]
                )
            );

            DROP TABLE IF EXISTS ${ObjectKeyInputTableName};

            CREATE TABLE $ObjectKeyInputTableName
            (
                [object_class_name] SYSNAME NOT NULL
            ,	[object_key_column_name] SYSNAME
            ,	[object_key_column_type] SYSNAME
            ,	[object_key_column_source] SYSNAME
            ,	PRIMARY KEY
                (
                    [object_class_name]
                ,	[object_key_column_name]
                )
            );

            $ObjectClassInsertSQL ;

            $MetadataKeyInsertSQL ;

            $ObjectKeyInsertSQL ;
    
            EXECUTE [config].[p_initialize_object_class]
                      @as_input_table_name = '$ObjectClassInputTableName'
            ,         @as_metadata_keys_table_name = '$MetadataKeyInputTableName'
            ,         @as_object_keys_table_name = '$ObjectKeyInputTableName'
             "
    Write-Verbose "Executing the following SQL query:`n $Query"

    # Execute the query defined above to initialize object class
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
