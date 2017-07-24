DROP TABLE IF EXISTS [config].[database];

CREATE TABLE [config].[database]
(
	[instance_id] INT NOT NULL
,	[database_id] INT NOT NULL 
,	[database_name] SYSNAME NOT NULL
,	CONSTRAINT pk_ref_db PRIMARY KEY([instance_id], [database_id])
);