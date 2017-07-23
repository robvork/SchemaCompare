DROP TABLE IF EXISTS [object].[function_param];

CREATE TABLE [object].[function_param]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [name] SYSNAME NOT NULL
, [column_encryption_key_database_name] SYSNAME NULL
, [column_encryption_key_id] INT NULL
, [default_value] SQL_VARIANT NULL
, [encryption_algorithm_name] SYSNAME NULL
, [encryption_type] INT NULL
, [encryption_type_desc] NVARCHAR(64) NULL
, [has_default_value] BIT NOT NULL
, [is_cursor_ref] BIT NOT NULL
, [is_nullable] BIT NULL
, [is_output] BIT NOT NULL
, [is_readonly] BIT NOT NULL
, [is_xml_document] BIT NOT NULL
, [max_length] SMALLINT NOT NULL
, [parameter_id] INT NOT NULL
, [precision] TINYINT NOT NULL
, [scale] TINYINT NOT NULL
, [system_type_id] TINYINT NOT NULL
, [user_type_id] INT NOT NULL
, [xml_collection_id] INT NOT NULL
);