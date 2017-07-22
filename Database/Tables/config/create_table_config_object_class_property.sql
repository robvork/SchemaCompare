DROP TABLE IF EXISTS [config].[object_class_property]

CREATE TABLE [config].[object_class_property]
(
	[object_class_id] [config].[ID]
,	[object_class_property_id] [config].[ID]
,	[object_class_property_name] [config].[NAME] NOT NULL
,	[object_class_property_type_name] SYSNAME
,	[object_class_property_is_nullable] BIT NOT NULL
,	[object_class_property_has_length] BIT NOT NULL
,	[object_class_property_length] INT NULL
,	[object_class_property_is_enabled] BIT NULL
,	CONSTRAINT pk_config_object_class_property
	PRIMARY KEY
	(
		[object_class_id]
	,	[object_class_property_id]
	)
);