DROP TABLE IF EXISTS [diff].[procedure_param];

CREATE TABLE [diff].[procedure_param]
(
  [parameter_id] INT NOT NULL
, [object_id] INT NOT NULL
, [schemacompare_source_database_id_left] INT NOT NULL
, [schemacompare_source_database_id_right] INT NOT NULL
, [schemacompare_source_instance_id_left] INT NOT NULL
, [schemacompare_source_instance_id_right] INT NOT NULL
, [side_indicator] NCHAR(1) NOT NULL
, [diff_column] SYSNAME NOT NULL
, [diff_value] SQL_VARIANT NULL
);