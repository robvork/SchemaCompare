DROP TABLE IF EXISTS [diff].[procedure];

CREATE TABLE [diff].[procedure]
(
  [object_id] INT NOT NULL
, [schema_id] INT NOT NULL
, [schemacompare_source_database_id_left] INT NOT NULL
, [schemacompare_source_database_id_right] INT NOT NULL
, [schemacompare_source_instance_id_left] INT NOT NULL
, [schemacompare_source_instance_id_right] INT NOT NULL
, [side_indicator] NCHAR(1) NOT NULL
, [diff_column] SYSNAME NOT NULL
, [diff_value] SQL_VARIANT NULL
);