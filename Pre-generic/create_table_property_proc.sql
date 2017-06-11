DROP TABLE IF EXISTS [property].[proc];

CREATE TABLE [property].[proc]
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[proc_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_s_proc PRIMARY KEY([database_id], [schema_name], [proc_name])
,	CONSTRAINT fk_s_proc_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES [instance].[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);
