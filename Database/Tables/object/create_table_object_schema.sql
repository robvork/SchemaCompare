DROP TABLE IF EXISTS [object].[schema];

CREATE TABLE [object].[schema]
(
  [schemacompare_source_instance_id] INT NOT NULL
, [schemacompare_source_database_id] INT NOT NULL
, [schema_id] INT NOT NULL
, [database_id] INT NOT NULL
, [schema_name] SYSNAME NOT NULL
, [name] SYSNAME NULL
, [principal_id] INT NULL
, CONSTRAINT pk_object_schema PRIMARY KEY
(
  [schemacompare_source_instance_id]
, [schemacompare_source_database_id]
, [database_id]
, [schema_id]
)
);