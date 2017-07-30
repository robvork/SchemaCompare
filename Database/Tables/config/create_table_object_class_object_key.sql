DROP TABLE IF EXISTS [config].[object_class_object_key];
GO

CREATE TABLE [config].[object_class_object_key]
(
	[object_class_id] [config].[ID] NOT NULL
,	[object_key_column_id]   INT
,	[object_key_column_name] SYSNAME
,	[object_key_column_type] SYSNAME
,	[object_key_column_source] SYSNAME
,	CONSTRAINT pk_config_object_class
	PRIMARY KEY
	(
		[object_class_id]
	,	[object_key_column_id]
	)
);

