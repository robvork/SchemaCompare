DROP TABLE IF EXISTS [diff].[schema];

CREATE TABLE [diff].[schema]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [schema_id] INT NOT NULL
, [source_database_id] INT NOT NULL
, [side_indicator] NCHAR(1) NOT NULL
, [diff_column] SYSNAME NOT NULL
, [diff_value] SQL_VARIANT NULL
);