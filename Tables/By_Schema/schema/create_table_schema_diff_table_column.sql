DROP TABLE IF EXISTS [schema].[diff_table_column];

CREATE TABLE [schema].[diff_table_column]
(
	[database_id_left] INT NOT NULL
,	[database_id_right] INT NOT NULL
,	[database_id_indicator] INT NOT NULL
,	[schema_name] SYSNAME NOT NULL
,	[table_name] SYSNAME NOT NULL
,	CONSTRAINT pk_s_diff_table_table PRIMARY KEY
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator] 
	,	[schema_name] 
	,	[table_name]
	)

,	CONSTRAINT fk_d_table_left_2_db 
	FOREIGN KEY ([database_id_left])
		REFERENCES [instance].[database]([database_id])

,	CONSTRAINT fk_d_table_right_2_db 
	FOREIGN KEY ([database_id_right])
		REFERENCES [instance].[database]([database_id])

,   CONSTRAINT chk_d_table_indicator_is_left_or_right
	CHECK (
		   [database_id_indicator] = [database_id_left]
			OR
		   [database_id_indicator] = [database_id_right]
		  )
);