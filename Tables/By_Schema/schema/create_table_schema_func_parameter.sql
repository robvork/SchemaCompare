DROP TABLE IF EXISTS [schema].[func_parameter];

CREATE TABLE [schema].[func_parameter]
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[func_name] SYSNAME NOT NULL 
,	[parameter_name] SYSNAME NOT NULL
,	CONSTRAINT 
		pk_s_table_column 
	PRIMARY KEY
	(
		[database_id]
	,	[schema_name]
	,	[func_name]
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