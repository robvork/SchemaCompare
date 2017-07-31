$ServerInstance = "ASPIRING\SQL16"
$Database = "SchemaCompare"
$SourceDatabases = @(
    "WideWorldImporters"
    "sample_db"
)

$Query = "
          WITH instance_values
          AS
          (
              SELECT [instance_id], [instance_name]
              FROM 
              (
                  VALUES (1, N'ASPIRING\SQL16')
              ) AS instance_values([instance_id], [instance_name])
          )
          MERGE INTO [config].[instance] AS TGT
          USING instance_values AS SRC
          ON SRC.[instance_id] = TGT.[instance_id] 
          WHEN NOT MATCHED BY TARGET THEN 
          INSERT ([instance_id], [instance_name])
          VALUES (SRC.[instance_id], SRC.[instance_name])
          ;

          WITH database_values
          AS
          (
              SELECT [instance_id]
              ,      ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [database_id]
              ,      [database_name]
              FROM 
              (
                  VALUES 
                  $(($SourceDatabases | ForEach-Object {"(1, '$_')"})-join "`n, ") 
              ) AS database_values([instance_id], [database_name])
          )
          MERGE INTO [config].[database] AS TGT
          USING database_values AS SRC
          ON SRC.[instance_id] = TGT.[instance_id] AND SRC.[database_id] = TGT.[database_id]
          WHEN NOT MATCHED BY TARGET THEN 
          INSERT ([instance_id], [database_id], [database_name])
          VALUES (SRC.[instance_id], SRC.[database_id], SRC.[database_name])
          ;
         "

Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query -Verbose 

$SourceDatabases | 
ForEach-Object {
    Sync-SchemaCompareObjectClass -ServerInstance $ServerInstance -Database $Database -SourceServerInstance $ServerInstance -SourceDatabase $_ -verbose 
}
