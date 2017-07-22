DROP TABLE IF EXISTS [config].[system_view];
GO 

CREATE TABLE [config].[system_view]
(
	[system_view_id] [config].[ID] 
,	[schema_id] [config].[ID] 
,	[system_view_name] [config].[NAME] UNIQUE
,	CONSTRAINT pk_config_system_view
	PRIMARY KEY
	(
		[schema_id]
	,	[system_view_id]
	)
);
