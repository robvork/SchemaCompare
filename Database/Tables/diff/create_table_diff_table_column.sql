DROP TABLE IF EXISTS [diff].[table_column];

CREATE TABLE [diff].[table_column]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [column_id] INT NOT NULL
, [object_id] INT NOT NULL
, [side_indicator] NCHAR(1) NOT NULL
, [diff_column] SYSNAME NOT NULL
, [diff_value] SQL_VARIANT NULL
);