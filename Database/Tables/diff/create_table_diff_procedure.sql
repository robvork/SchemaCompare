DROP TABLE IF EXISTS [diff].[procedure];

CREATE TABLE [diff].[procedure]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [schema_id] INT NOT NULL
, [side_indicator] NCHAR(1) NOT NULL
, [diff_column] SYSNAME NOT NULL
, [diff_value] SQL_VARIANT NULL
);