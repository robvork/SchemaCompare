function Sync-SchemaCompareObjectClass
{
    [CmdletBinding()]
    param 
    (
        $ServerInstance 
    ,
        $Database 
    ,
        $SourceServerInstance 
    ,   
        $SourceDatabase 
    ,
        $ObjectClassName 
    )

    try 
    {
        Set-StrictMode -Version Latest
        <#
        $ServerInstanceValid = Test-SQLServerInstance -ServerInstance $ServerInstance

        if(-not $ServerInstanceValid)
        {
            throw "'$ServerInstance' is not a valid SQL Server Instance"
        }

        $DatabaseValid = Test-SQLServerDatabase -ServerInstance $ServerInstance -Database $Database
        if(-not $DatabaseValid)
        {
            throw "'$Database' is not a valid database on '$ServerInstance'"
        }

        $ObjectClasses = Get-SchemaCompareObjectClass
        $ObjectClassNameValid = [bool] ($ObjectClasses | Where-Object -FilterScript {$_.ObjectClassName -eq $ObjectClassName})
        if(-not $ObjectClassNameValid)
        {
            throw "'$ObjectClassName' is not a valid SchemaCompare object class"
        }

        $SourceServerInstances = Get-SchemaCompareSourceInstance -ServerInstance $ServerInstance -Database $Database 
        $SourceDatabases = Get-SchemaCompareSourceDatabase -ServerInstance $ServerInstance -Database $Database 

        $SourceServerInstanceRegistered = [bool] ($SourceServerInstances | Where-Object -FilterScript {$_.SourceServerInstance -eq $SourceServerInstance})

        if(-not $SourceServerInstanceRegistered)
        {
            throw "'$SourceServerInstance' is not a registered SchemaCompare source server instance"
        }
    
        $SourceServerInstanceValid = Test-SQLServerInstance -ServerInstance $SourceServerInstance
        if(-not $SourceServerInstanceValid)
        {
            throw "'$SourceServerInstance' is not a valid SQL Server instance."
        }

        $SourceDatabaseRegistered = [bool] ($SourceDatabases | Where-Object -FilterScript {$_.SourceServerInstance -eq $SourceServerInstance -and $_.SourceDatabase -eq $SourceDatabase})

        if(-not $SourceDatabaseRegistered)
        {
            throw "'$SourceDatabase' is not a registered SchemaCompare source database on '$SourceServerInstance'"
        }

        $SourceDatabaseValid = Test-SQLServerDatabase -ServerInstance $SourceServerInstance -Database $SourceDatabase
        if(-not $SourceDatabaseValid)
        {
            throw "'SourceDatabase' is not a valid database on '$SourceServerInstance'"
        }
        #>

        # Get object class query
        $ObjectClassQuery = Get-SchemaCompareObjectClassQuery -ServerInstance $ServerInstance -Database $Database -ObjectClassName $ObjectClassName -SourceDatabase $SourceDatabase
    
        $ObjectClassQuery | 
        ForEach-Object {
            $Query = $_.object_class_query; 
            $ObjectClassName = $_.object_class_name
            $CurrentValuesTableName = "#${ObjectClassName}_current_values"
            Write-Verbose "Syncing $ObjectClassName";
            $Query = "WITH current_values AS ($Query) 
                      
                      SELECT *, current_values
                      INTO $CurrentValuesTableName
                      FROM current_values;

                      EXECUTE [config].[p_sync_object_class]
                            @as_instance_name = '$SourceServerInstance'
                      ,     @as_database_name = '$SourceDatabase'
                      ,     @as_object_class_name = '$ObjectClassName'
                      ,     @as_input_table_name = '$CurrentValuesTableName'
            "

            Write-Verbose "Executing the following query:`n${Query}"
            Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query
        }
        
    }
    catch 
    {
        throw $_.Exception
    }
    

}

function Sync-SchemaCompareObjectToSubobjectMapping
{
    [CmdletBinding()]
    param 
    (
        $ServerInstance 
    ,   
        $Database
    ,   
        $ObjectClassName = $null 
    ,
        $SubobjectClassName = $null
    )
}