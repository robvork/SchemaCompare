DROP TABLE IF EXISTS [property].[func];

CREATE TABLE [property].[func]
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[func_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_s_func PRIMARY KEY([database_id], [schema_name], [func_name])
,	CONSTRAINT fk_s_func_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES [instance].[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);
