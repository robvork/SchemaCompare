DROP TABLE IF EXISTS [object].[view_column];

CREATE TABLE [object].[view_column]
(
  [schemacompare_source_database_id] INT NOT NULL
, [schemacompare_source_instance_id] INT NOT NULL
, [column_id] INT NOT NULL
, [object_id] INT NOT NULL
, [column_name] SYSNAME NOT NULL
, [collation_name] SYSNAME NULL
, [column_encryption_key_database_name] SYSNAME NULL
, [column_encryption_key_id] INT NULL
, [default_object_id] INT NULL
, [encryption_algorithm_name] SYSNAME NULL
, [encryption_type] INT NULL
, [encryption_type_desc] NVARCHAR(64) NULL
, [generated_always_type] TINYINT NULL
, [generated_always_type_desc] NVARCHAR(60) NULL
, [is_ansi_padded] BIT NULL
, [is_column_set] BIT NULL
, [is_computed] BIT NULL
, [is_dts_replicated] BIT NULL
, [is_filestream] BIT NULL
, [is_hidden] BIT NULL
, [is_identity] BIT NULL
, [is_masked] BIT NULL
, [is_merge_published] BIT NULL
, [is_non_sql_subscribed] BIT NULL
, [is_nullable] BIT NULL
, [is_replicated] BIT NULL
, [is_rowguidcol] BIT NULL
, [is_sparse] BIT NULL
, [is_xml_document] BIT NULL
, [max_length] SMALLINT NULL
, [name] SYSNAME NULL
, [precision] TINYINT NULL
, [rule_object_id] INT NULL
, [scale] TINYINT NULL
, [system_type_id] TINYINT NULL
, [user_type_id] INT NULL
, [xml_collection_id] INT NULL
, CONSTRAINT pk_object_view_column PRIMARY KEY
(
  instance_id
, database_id
, object_id
, column_id
)
);