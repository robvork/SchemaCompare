DROP TABLE IF EXISTS [object].[schema];

CREATE TABLE [object].[schema]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [schema_id] INT NOT NULL
, [source_database_id] INT NOT NULL
, [schema_name] SYSNAME NOT NULL
, [name] SYSNAME NULL
, [principal_id] INT NULL
, CONSTRAINT pk_object_schema PRIMARY KEY
(
  instance_id
, database_id
, source_database_id
, schema_id
)
);