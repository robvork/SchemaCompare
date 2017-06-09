DROP TABLE IF EXISTS [config].[object_class_property]

CREATE TABLE [config].[object_class_property]
(
	[object_class_id] [config].[ID]
,	[object_class_property_id] [config].[ID]
,	[object_class_system_type_id] [config].[ID]
,	[object_class_property_name] [config].[NAME]
,	CONSTRAINT pk_config_object_class_property
	PRIMARY KEY
	(
		[object_class_id]
	,	[object_class_property_id]
	)
);