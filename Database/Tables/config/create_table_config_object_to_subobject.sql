DROP TABLE IF EXISTS [config].[object_to_subobject];

CREATE TABLE [config].[object_to_subobject]
(
	[object_class_id] [config].[ID]
,	[subobject_class_id] [config].[ID]
,	CONSTRAINT 
		[pk_config_object_to_subobject]
	PRIMARY KEY
	(
		[object_class_id]
	,	[subobject_class_id]
	)
);