DROP TABLE IF EXISTS [config].[database];

CREATE TABLE [config].[database]
(
	[database_id] INT NOT NULL 
,	[database_name] SYSNAME NOT NULL
,	CONSTRAINT pk_ref_db PRIMARY KEY([database_id])
);