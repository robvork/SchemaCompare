DROP TABLE IF EXISTS [config].[object_class];

CREATE TABLE [config].[object_class]
(
	[object_class_id] [config].[ID] 
,	[object_class_name] [config].[NAME] UNIQUE
,	[object_class_view_name] [config].[NAME] UNIQUE
,	CONSTRAINT pk_config_object_class
	PRIMARY KEY
	(
		object_class_id
	)
);
