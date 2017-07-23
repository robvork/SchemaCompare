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