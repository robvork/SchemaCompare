function Initialize-SchemaCompareDB
{
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   [String] $Database
    ,   [String[]] $CreateSchemaScripts
    ,   [String[]] $CreateUDDTScripts
    ,   [String[]] $CreateTableScripts
    ,   [String[]] $CreateForeignKeyScripts
    ,   [String[]] $CreateProcedureScripts
    )

    try
    {
        # Store connection parameters for uniform and concise use across this function
        $ConnectionParams = @{
            ServerInstance = $ServerInstance;
            Database = $Database; 
        }

        # Create DB
        # TODO: Prompt user to confirm database drop if it exists
        $CreateDBSQL = "IF EXISTS(SELECT * FROM sys.databases WHERE [name] = '$Database')
                        BEGIN
                            ALTER DATABASE [$Database]
                            SET SINGLE_USER
                            WITH ROLLBACK IMMEDIATE;

                            DROP DATABASE [$Database];
                        END;
                        GO

                        CREATE DATABASE [$Database];"
                        
        Write-Verbose "Creating database '$Database' on SQL Server instance '$ServerInstance'"
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Database master -Query $CreateDBSQL -ErrorAction Stop
        Write-Verbose "Database creation SUCCESS"

        # Create schemas
        Write-Verbose "Creating schemas"
        foreach($csScript in $CreateSchemaScripts)
        {
            Write-Verbose "Creating schema by running '$csScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $csScript -ErrorAction Stop
            Write-Verbose "Schema created successfully"
        }
        Write-Verbose "Schema creation SUCCESS"

        #Create UDDTs
        Write-Verbose "Creating user-defined data types"
        foreach($cuddtScript in $CreateUDDTScripts)
        {
            Write-Verbose "Creating user-defined data type by running '$cuddtScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $cuddtScript -ErrorAction Stop 
            Write-Verbose "User-defined data type created successfully"
        }
        Write-Verbose "User-defined data type creation SUCCESS"

        #Create tables
        Write-Verbose "Creating tables"
        foreach($ctScript in $CreateTableScripts)
        {
            Write-Verbose "Creating table by running '$ctScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $ctScript -ErrorAction Stop 
            Write-Verbose "Table created successfully"
        }
        Write-Verbose "Table creation SUCCESS"

        #Create foreign keys
        Write-Verbose "Creating foreign keys"
        foreach($cfkScript in $CreateForeignKeyScripts)
        {
            Write-Verbose "Creating foreign key by running '$cfkScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $cfkScript -ErrorAction Stop 
            Write-Verbose "Table created successfully"
        }
        Write-Verbose "Foreign key creation SUCCESS"

        #Create procedures
        Write-Verbose "Creating procedures"
        foreach($cpScript in $CreateForeignKeyScripts)
        {
            Write-Verbose "Creating procedure by running '$cpScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $cpScript -ErrorAction Stop 
            Write-Verbose "Procedure created successfully"
        }
        Write-Verbose "Procedure creation SUCCESS"
    }
    catch
    {
        throw $_.Exception 
    }
}