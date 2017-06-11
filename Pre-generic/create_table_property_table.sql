DROP TABLE IF EXISTS [property].[table];

CREATE TABLE [property].[table]
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[table_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_s_table PRIMARY KEY([database_id], [table_name])
,	CONSTRAINT fk_s_table_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES [instance].[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);
