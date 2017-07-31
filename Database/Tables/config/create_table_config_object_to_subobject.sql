DROP TABLE IF EXISTS [config].[object_to_subobject];

CREATE TABLE [config].[object_to_subobject]
(
	[object_class_id] [config].[ID] NOT NULL
,	[subobject_class_id] [config].[ID] NOT NULL
,	[mapping_table_schema] SYSNAME NOT NULL
,	[mapping_table_name] SYSNAME NOT NULL
,	CONSTRAINT 
		[pk_config_object_to_subobject]
	PRIMARY KEY
	(
		[object_class_id]
	,	[subobject_class_id]
	)
);