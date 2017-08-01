DROP TABLE IF EXISTS [diff].[database];

CREATE TABLE [diff].[database]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [source_database_id] INT NOT NULL
, [side_indicator] NCHAR(1) NOT NULL
, [diff_column] SYSNAME NOT NULL
, [diff_value] SQL_VARIANT NULL
);