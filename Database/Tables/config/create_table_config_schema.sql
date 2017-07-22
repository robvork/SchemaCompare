DROP TABLE IF EXISTS [config].[schema];
GO 

CREATE TABLE [config].[schema]
(
	[schema_id] [config].[ID] 
,	[schema_name] [config].[NAME] UNIQUE
,	CONSTRAINT pk_config_schema
	PRIMARY KEY
	(
		[schema_id]
	)
);
