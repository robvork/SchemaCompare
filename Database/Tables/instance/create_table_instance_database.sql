DROP TABLE IF EXISTS [instance].[database];

CREATE TABLE [instance].[database]
(
	[database_id] INT NOT NULL 
,	[database_name] SYSNAME NOT NULL
,	CONSTRAINT pk_ref_db PRIMARY KEY([database_id])
);