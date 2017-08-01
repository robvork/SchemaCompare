DROP TABLE IF EXISTS [config].[object_class_metadata_key];
GO

CREATE TABLE [config].[object_class_metadata_key]
(
	[object_class_id] [config].[ID] NOT NULL
,	[metadata_key_column_id]   INT NOT NULL
,	[metadata_key_column_name] SYSNAME NOT NULL
,	[metadata_key_column_type] SYSNAME NOT NULL
,	[metadata_key_column_source] SYSNAME NOT NULL
,	[is_parent_metadata_key] BIT NOT NULL
,	CONSTRAINT pk_config_object_class_metadata_key
	PRIMARY KEY
	(
		[object_class_id]
	,	[metadata_key_column_id]
	)
);

