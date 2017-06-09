DROP TABLE IF EXISTS [db].[schema];

CREATE TABLE [db].[schema]
(
	[database_id] [config].[ID]
,	[schema_id]   [config].[ID]
,	[schema_name] [config].[NAME]
,	CONSTRAINT
		[pk_db_schema]
	PRIMARY KEY
	(
		[database_id]
	,	[schema_id]
	)
);