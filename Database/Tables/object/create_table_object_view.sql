DROP TABLE IF EXISTS [object].[view];

CREATE TABLE [object].[view]
(
  [schemacompare_source_instance_id] INT NOT NULL
, [schemacompare_source_database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [schema_id] INT NOT NULL
, [view_name] SYSNAME NOT NULL
, [create_date] DATETIME NULL
, [has_opaque_metadata] BIT NULL
, [has_replication_filter] BIT NULL
, [has_unchecked_assembly_data] BIT NULL
, [is_date_correlation_view] BIT NULL
, [is_ms_shipped] BIT NULL
, [is_published] BIT NULL
, [is_replicated] BIT NULL
, [is_schema_published] BIT NULL
, [is_tracked_by_cdc] BIT NULL
, [modify_date] DATETIME NULL
, [name] SYSNAME NULL
, [parent_object_id] INT NULL
, [principal_id] INT NULL
, [type] CHAR(2) NULL
, [type_desc] NVARCHAR(60) NULL
, [with_check_option] BIT NULL
, CONSTRAINT pk_object_view PRIMARY KEY
(
  [schemacompare_source_instance_id]
, [schemacompare_source_database_id]
, [schema_id]
, [object_id]
)
);