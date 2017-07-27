Import-Module RVK.SchemaCompare -Force 

[string] $ServerInstance = "ASPIRING\SQL16"
[string] $Database = "SchemaCompare"
[bool] $UseForce = $true

Install-SchemaCompare -ServerInstance $ServerInstance -Database $Database -Force:($UseForce) -Verbose

$Query = "INSERT INTO [config].[instance] (instance_id, instance_name) 
                                   VALUES (1          , 'ASPIRING\SQL16');
          INSERT INTO [config].[database] (instance_id, database_id, database_name)
                                   VALUES (1          , 1          , 'WideWorldImporters');
         "

Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query
          