DROP TABLE IF EXISTS [object].[function];

CREATE TABLE [object].[function]
(
  [schemacompare_source_instance_id] INT NOT NULL
, [schemacompare_source_database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [schema_id] INT NOT NULL
, [function_name] SYSNAME NOT NULL
, [create_date] DATETIME NULL
, [is_ms_shipped] BIT NULL
, [is_published] BIT NULL
, [is_schema_published] BIT NULL
, [modify_date] DATETIME NULL
, [name] SYSNAME NULL
, [parent_object_id] INT NULL
, [principal_id] INT NULL
, [type] CHAR(2) NULL
, [type_desc] NVARCHAR(60) NULL
, CONSTRAINT pk_object_function PRIMARY KEY
(
  [schemacompare_source_instance_id]
, [schemacompare_source_database_id]
, [schema_id]
, [object_id]
)
);