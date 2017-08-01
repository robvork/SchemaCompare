DROP TABLE IF EXISTS [diff].[function_param];

CREATE TABLE [diff].[function_param]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [parameter_id] INT NOT NULL
, [object_id] INT NOT NULL
, [side_indicator] NCHAR(1) NOT NULL
, [diff_column] SYSNAME NOT NULL
, [diff_value] SQL_VARIANT NULL
);