DROP TABLE IF EXISTS [property].[view];

CREATE TABLE [property].[view]
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[view_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_s_view PRIMARY KEY([database_id], [schema_name], [view_name])
,	CONSTRAINT fk_s_view_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES [instance].[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);
