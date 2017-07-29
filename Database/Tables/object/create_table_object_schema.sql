DROP TABLE IF EXISTS [object].[schema];

CREATE TABLE [object].[schema]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT IDENTITY(1, 1) NOT NULL
, [name] SYSNAME NOT NULL
, [principal_id] INT NULL
, [schema_id] INT NULL
);