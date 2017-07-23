DROP TABLE IF EXISTS [object].[table_column];

CREATE TABLE [object].[table_column]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [name] SYSNAME NOT NULL
, [collation_name] SYSNAME NULL
, [column_encryption_key_database_name] SYSNAME NULL
, [column_encryption_key_id] INT NULL
, [column_id] INT NOT NULL
, [default_object_id] INT NOT NULL
, [encryption_algorithm_name] SYSNAME NULL
, [encryption_type] INT NULL
, [encryption_type_desc] NVARCHAR(64) NULL
, [generated_always_type] TINYINT NULL
, [generated_always_type_desc] NVARCHAR(60) NULL
, [is_ansi_padded] BIT NOT NULL
, [is_column_set] BIT NULL
, [is_computed] BIT NOT NULL
, [is_dts_replicated] BIT NULL
, [is_filestream] BIT NOT NULL
, [is_hidden] BIT NULL
, [is_identity] BIT NOT NULL
, [is_masked] BIT NULL
, [is_merge_published] BIT NULL
, [is_non_sql_subscribed] BIT NULL
, [is_nullable] BIT NULL
, [is_replicated] BIT NULL
, [is_rowguidcol] BIT NOT NULL
, [is_sparse] BIT NULL
, [is_xml_document] BIT NOT NULL
, [max_length] SMALLINT NOT NULL
, [precision] TINYINT NOT NULL
, [rule_object_id] INT NOT NULL
, [scale] TINYINT NOT NULL
, [system_type_id] TINYINT NOT NULL
, [user_type_id] INT NOT NULL
, [xml_collection_id] INT NOT NULL
);