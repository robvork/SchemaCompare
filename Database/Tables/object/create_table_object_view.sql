DROP TABLE IF EXISTS [object].[view];

CREATE TABLE [object].[view]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [name] SYSNAME NOT NULL
, [create_date] DATETIME NOT NULL
, [has_opaque_metadata] BIT NOT NULL
, [has_replication_filter] BIT NULL
, [has_unchecked_assembly_data] BIT NOT NULL
, [is_date_correlation_view] BIT NOT NULL
, [is_ms_shipped] BIT NOT NULL
, [is_published] BIT NOT NULL
, [is_replicated] BIT NULL
, [is_schema_published] BIT NOT NULL
, [is_tracked_by_cdc] BIT NULL
, [modify_date] DATETIME NOT NULL
, [parent_object_id] INT NOT NULL
, [principal_id] INT NULL
, [schema_id] INT NOT NULL
, [type] CHAR(2) NULL
, [type_desc] NVARCHAR(60) NULL
, [with_check_option] BIT NOT NULL
);