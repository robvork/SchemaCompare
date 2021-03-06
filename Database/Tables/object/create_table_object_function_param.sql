DROP TABLE IF EXISTS [object].[function_param];

CREATE TABLE [object].[function_param]
(
  [schemacompare_source_instance_id] INT NOT NULL
, [schemacompare_source_database_id] INT NOT NULL
, [parameter_id] INT NOT NULL
, [object_id] INT NOT NULL
, [parameter_name] SYSNAME NOT NULL
, [column_encryption_key_database_name] SYSNAME NULL
, [column_encryption_key_id] INT NULL
, [default_value] SQL_VARIANT NULL
, [encryption_algorithm_name] SYSNAME NULL
, [encryption_type] INT NULL
, [encryption_type_desc] NVARCHAR(64) NULL
, [has_default_value] BIT NULL
, [is_cursor_ref] BIT NULL
, [is_nullable] BIT NULL
, [is_output] BIT NULL
, [is_readonly] BIT NULL
, [is_xml_document] BIT NULL
, [max_length] SMALLINT NULL
, [name] SYSNAME NULL
, [precision] TINYINT NULL
, [scale] TINYINT NULL
, [system_type_id] TINYINT NULL
, [user_type_id] INT NULL
, [xml_collection_id] INT NULL
, CONSTRAINT pk_object_function_param PRIMARY KEY
(
  [schemacompare_source_instance_id]
, [schemacompare_source_database_id]
, [object_id]
, [parameter_id]
)
);