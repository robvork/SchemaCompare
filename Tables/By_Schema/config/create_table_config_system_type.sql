DROP TABLE IF EXISTS [config].[system_type]

CREATE TABLE [config].[system_type]
(
	[system_type_id]   [config].[ID]
,	[system_type_name] [config].[NAME]
,	[system_type_has_length] BIT NOT NULL
,	CONSTRAINT 
		[pk_config_system_type]
	PRIMARY KEY 
	(
		[system_type_id]
	)
);
