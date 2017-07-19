CREATE TABLE [config].[next_id]
(
	[system_object_id] [config].[ID]
,	[next_id] [config].[ID]
,	CONSTRAINT
		[pk_config_next_id]
	PRIMARY KEY
	(	
		[system_object_id]
	)
,	CONSTRAINT 
		[ck_next_id_positive]
	CHECK
		([next_id] > 0)
);