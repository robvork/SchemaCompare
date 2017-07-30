DROP TABLE IF EXISTS [config].[object_class];

CREATE TABLE [config].[object_class]
(
	[object_class_id] [config].[ID] NOT NULL
,	[object_class_name] [config].[NAME] UNIQUE NOT NULL
,	[object_class_source] NVARCHAR(MAX) NOT NULL
,	[object_class_source_alias] NVARCHAR(10) NOT NULL
,	[table_schema_name] SYSNAME NOT NULL
,	[table_name] SYSNAME NOT NULL
,	[view_schema_name] SYSNAME NOT NULL
,	[view_name] SYSNAME NOT NULL
,	CONSTRAINT pk_config_object_class
	PRIMARY KEY
	(
		object_class_id
	)
);
