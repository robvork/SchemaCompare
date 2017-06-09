DROP TABLE IF EXISTS [property].[proc_parameter];

CREATE TABLE [property].[proc_parameter]
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[proc_name] SYSNAME NOT NULL 
,	[parameter_name] SYSNAME NOT NULL
,	CONSTRAINT 
		pk_s_table_column 
	PRIMARY KEY
	(
		[database_id]
	,	[schema_name]
	,	[proc_name]
	,	[parameter_name]
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
