DROP TABLE IF EXISTS [property].[view_column];

CREATE TABLE [property].[view_column]
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[view_name] SYSNAME NOT NULL 
,	[column_name] SYSNAME NOT NULL
,	CONSTRAINT 
		pk_s_table_column 
	PRIMARY KEY
	(
		[database_id]
	,	[schema_name]
	,	[view_name]
	,	[column_name]
	)
,	CONSTRAINT fk_s_view_column_2_ref_db 
	FOREIGN KEY 
	(	
		[database_id]
	)
	REFERENCES 
		[instance].[database]
	(
		[database_id]
	)
	ON DELETE CASCADE
	ON UPDATE CASCADE 
);
