DROP TABLE IF EXISTS [object].[schema];

CREATE TABLE [object].[schema]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [name] SYSNAME NOT NULL
, [principal_id] INT NULL
, [schema_id] INT NOT NULL
);