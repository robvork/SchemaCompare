DROP TABLE IF EXISTS [object].[table];

CREATE TABLE [object].[table]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [schema_id] INT NOT NULL
, [table_name] SYSNAME NOT NULL
, [create_date] DATETIME NULL
, [durability] TINYINT NULL
, [durability_desc] NVARCHAR(60) NULL
, [filestream_data_space_id] INT NULL
, [has_replication_filter] BIT NULL
, [has_unchecked_assembly_data] BIT NULL
, [history_table_id] INT NULL
, [is_external] BIT NULL
, [is_filetable] BIT NULL
, [is_memory_optimized] BIT NULL
, [is_merge_published] BIT NULL
, [is_ms_shipped] BIT NULL
, [is_published] BIT NULL
, [is_remote_data_archive_enabled] BIT NULL
, [is_replicated] BIT NULL
, [is_schema_published] BIT NULL
, [is_sync_tran_subscribed] BIT NULL
, [is_tracked_by_cdc] BIT NULL
, [large_value_types_out_of_row] BIT NULL
, [lob_data_space_id] INT NULL
, [lock_escalation] TINYINT NULL
, [lock_escalation_desc] NVARCHAR(60) NULL
, [lock_on_bulk_load] BIT NULL
, [max_column_id_used] INT NULL
, [modify_date] DATETIME NULL
, [name] SYSNAME NULL
, [parent_object_id] INT NULL
, [principal_id] INT NULL
, [temporal_type] TINYINT NULL
, [temporal_type_desc] NVARCHAR(60) NULL
, [text_in_row_limit] INT NULL
, [type] CHAR(2) NULL
, [type_desc] NVARCHAR(60) NULL
, [uses_ansi_nulls] BIT NULL
, CONSTRAINT pk_object_table PRIMARY KEY
(
  instance_id
, database_id
, schema_id
, object_id
)
);