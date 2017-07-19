DROP TABLE IF EXISTS [config].[instance];

CREATE TABLE [config].[instance]
(
	[instance_id] [config].[ID]
,	[instance_name] [config].[NAME]
,	CONSTRAINT
		[pk_config_instance]
	PRIMARY KEY
	(
		[instance_id]
	)
);
