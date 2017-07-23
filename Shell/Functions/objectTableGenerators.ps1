function Get-SchemaCompareObjectClassColumnSQL 
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        [String] $ServerInstance 
    ,
        [Parameter(Mandatory=$True)]
        [String] $Database 
    ,
        [ValidateNotNullOrEmpty()]
        [String] $Name 
    )

     $ConnectionParams = @{
        ServerInstance=$ServerInstance;
        Database=$Database; 
    }

    $Query = "EXECUTE [config].[p_create_object_column_code]
                      @as_object_class_name = '$Name'
             "

    Invoke-Sqlcmd2 @ConnectionParams -Query $Query |
    Select-Object -ExpandProperty column_sql
}

function Get-SchemaCompareObjectClassTableSQL 
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        [String] $ServerInstance 
    ,
        [Parameter(Mandatory=$True)]
        [String] $Database 
    ,
        [ValidateNotNullOrEmpty()]
        [String] $Name 
    )

     $ConnectionParams = @{
        ServerInstance=$ServerInstance;
        Database=$Database; 
    }


    $ColumnSQL = Get-SchemaCompareObjectClassColumnSQL @ConnectionParams -Name $Name

    # add 2 spaces before the first row so that the column names are aligned after we combine the columns into one string
    $ColumnSQL[0] = "  " + $ColumnSQL[0]
    $ColumnSQL = $ColumnSQL -join "`n, "

    # Put all objects into an [object] schema table bearing the object class name
    $TableSQL = @(
                    "DROP TABLE IF EXISTS [object].[$Name];"
                    ""
                    "CREATE TABLE [object].[$Name]" 
                    "(" 
                        $ColumnSQL 
                    ");"
                 ) -join "`n"

    Write-Output $TableSQL
}

function New-SchemaCompareObjectClassTableScript
{
    [CmdletBinding()]
    param 
    (
        [string] $ServerInstance
    ,   
        [string] $Database 
    ,
        [string] $Name
    ,
        [string] $Path 
    )

    $ScriptName = "create_table_object_${Name}.sql"
    $TableCreateSQL = Get-SchemaCompareObjectClassTableSQL -ServerInstance $ServerInstance -Database $Database -Name $Name 
    New-Item -Path $Path -Name $ScriptName -Value $TableCreateSQL | Out-Null 
}

function New-SchemaCompareObjectToSubobjectMappingTableScript
{
    [CmdletBinding()]
    param
    (
        [string] $ServerInstance 
    ,   
        [string] $Database
    ,
        [string] $ObjectClassName
    ,   
        [string] $SubobjectClassName
    ,   
        [string] $Path
    )

    $ClassMapping = Get-SchemaCompareObjectClassToSubobjectClass -ServerInstance $ServerInstance -Database $Database -ObjectClassName $ObjectClassName -SubobjectClassName $SubobjectClassName
    $MappingTableSchema = ($ClassMapping.mapping_table_schema -replace "\[|\]", "")
    $MappingTableName = ($ClassMapping.mapping_table_name -replace "\[|\]", "")

    $TableSQL = "
    DROP TABLE IF EXISTS [$MappingTableSchema].[$MappingTableName]; 
    GO 

    CREATE TABLE [$MappingTableSchema].[$MappingTableName]
    (
        [object_class_id] INT NOT NULL
    ,   [subobject_class_id] INT NOT NULL
    ,   CONSTRAINT pk_${MappingTableName} PRIMARY KEY
        (
            [object_class_id]
        ,   [subobject_class_id]
        )  
    );
    GO
    "

    New-Item -Path $Path -Name "create_table_${MappingTableSchema}_${MappingTableName}.sql" -Value $TableSQL -ItemType File | Out-Null
}
