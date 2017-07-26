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

        # Get object class source
        # Query object class data
        # Call sync procedure
        
    }
    catch 
    {
        throw $_.Exception
    }
    

}