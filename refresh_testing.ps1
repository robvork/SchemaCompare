$ServerInstance = "ASPIRING\SQL16"
$Database = "SchemaCompare"

$Query = "INSERT INTO [config].[instance] (instance_id, instance_name) 
                                   VALUES (1          , 'ASPIRING\SQL16');
          INSERT INTO [config].[database] (instance_id, database_id, database_name)
                                   VALUES (1          , 1          , 'sample_db');
         "

# Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query 

Sync-SchemaCompareObjectClass -ServerInstance $ServerInstance -Database $Database -SourceServerInstance $ServerInstance -SourceDatabase "sample_db" -verbose #-ObjectClassName "Table" 