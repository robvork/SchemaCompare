DROP TABLE IF EXISTS [object].[procedure_param];

CREATE TABLE [object].[procedure_param]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT IDENTITY(1, 1) NOT NULL
, [name] SYSNAME NOT NULL
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
, [parameter_id] INT NULL
, [precision] TINYINT NULL
, [scale] TINYINT NULL
, [system_type_id] TINYINT NULL
, [user_type_id] INT NULL
, [xml_collection_id] INT NULL
);