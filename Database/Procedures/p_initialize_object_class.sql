DROP PROCEDURE IF EXISTS [config].[p_initialize_object_class];
GO

CREATE PROCEDURE [config].[p_initialize_object_class]
(
	@ai_debug_level INT = 0
,	@as_input_table_name SYSNAME
,	@as_metadata_keys_table_name SYSNAME
,	@as_object_keys_table_name SYSNAME
)
AS
BEGIN
	DECLARE @ls_sql NVARCHAR(MAX); 

	EXEC [config].[p_initialize_next_id]
		@as_schema_name = 'config'
	,	@as_table_name = 'object_class'
	;	

	IF @ai_debug_level > 1
	BEGIN
		SELECT '[config].[object_class] at the BEGINNING of procedure';
		SELECT * FROM [config].[object_class];
	END;


	IF EXISTS(SELECT * FROM [config].[object_class])
	BEGIN
		TRUNCATE TABLE [config].[object_class];

		IF @ai_debug_level > 1
		BEGIN
		

			SELECT '[config].[object_class] has been truncated and is now empty';
		END;
	END;
	

	DROP TABLE IF EXISTS #object_class;

	CREATE TABLE #object_class
	(
		row_num INT NOT NULL
	,	row_id INT NULL
	,	object_class_name NVARCHAR(128) NOT NULL
	,	object_class_source NVARCHAR(MAX) NOT NULL
	,	object_class_source_alias NVARCHAR(10) NOT NULL
	,	view_schema_name SYSNAME NOT NULL
	,	view_name SYSNAME NOT NULL
	);

	DROP TABLE IF EXISTS #metadata_keys; 

	CREATE TABLE #metadata_keys
	(
		[object_class_id] INT NOT NULL
	,	[metadata_key_column_id]   INT
	,	[metadata_key_column_name] SYSNAME
	,	[metadata_key_column_type] SYSNAME
	,	[metadata_key_column_source] SYSNAME
	,	PRIMARY KEY
		(
			[object_class_id]
		,	[metadata_key_column_id]
		)
	);

	DROP TABLE IF EXISTS #object_keys;
	
	CREATE TABLE #object_keys
	(
		[object_class_id] INT NOT NULL
	,	[object_key_column_id]   INT
	,	[object_key_column_name] SYSNAME
	,	[object_key_column_type] SYSNAME
	,	[object_key_column_source] SYSNAME
	,	PRIMARY KEY
		(
			[object_class_id]
		,	[object_key_column_id]
		)
	);

	/*******************************************************************************
	Extract data from object class input table into local table, prepare for id assignment
	*******************************************************************************/

	SET @ls_sql = CONCAT 
	(
		N'
		INSERT INTO #object_class 
		(
			row_num
		,	object_class_name 
		,	object_class_source
		,	object_class_source_alias 
		,	view_schema_name
		,	view_name
		)
		SELECT 
			ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		,	I.[object_class_name] 
		,	I.[object_class_source]
		,	I.[object_class_source_alias]
		,	I.[view_schema_name]
		,	I.[view_name] 
		FROM ', @as_input_table_name, N' AS I
		;'
	);
	
	IF @ai_debug_level > 0
		PRINT CONCAT(N'Executing the following in DSQL: ', @ls_sql);
	
	EXEC(@ls_sql);
	
	/*******************************************************************************
	Generate a new object_class_id for each row of #object_class. 
	Set #object_class.[row_num] to these values
	*******************************************************************************/
	IF @ai_debug_level > 1
	BEGIN
		SELECT '#object_class BEFORE setting IDs';
		SELECT * FROM #object_class; 
	END;

	EXECUTE [config].[p_get_next_id] 
		@as_schema_name = 'config'
	,	@as_table_name = 'object_class'
	,	@as_work_table_name = '#object_class'
	;

	IF @ai_debug_level > 1
	BEGIN
		SELECT '#object_class AFTER setting IDs';
		SELECT * FROM #object_class; 
	END;

	/*******************************************************************************
	With the newly assigned object_class_ids, join the metadata and object key 
	input tables with #object_class to get the object class ids and key data
	*******************************************************************************/

	SET @ls_sql = CONCAT 
	(
		N'
		INSERT INTO #metadata_keys 
		(
			[object_class_id] 
		,	[metadata_key_column_id]  
		,	[metadata_key_column_name] 
		,	[metadata_key_column_type] 
		,	[metadata_key_column_source] 
		)
		SELECT 
			OC.[row_id] 
		,	ROW_NUMBER() OVER (PARTITION BY OC.[row_id] ORDER BY (SELECT NULL))
		,	M.[metadata_key_column_name] 
		,	M.[metadata_key_column_type] 
		,	M.[metadata_key_column_source] 
		FROM ', @as_metadata_keys_table_name, N' AS M
			INNER JOIN #object_class AS OC
				ON M.[object_class_name] = OC.[object_class_name]
		;'
	);
	
	IF @ai_debug_level > 0
		PRINT CONCAT(N'Executing the following in DSQL: ', @ls_sql);
	
	EXEC(@ls_sql);

	SET @ls_sql = CONCAT 
	(
		N'
		INSERT INTO #object_keys
		(
			[object_class_id] 
		,	[object_key_column_id]   
		,	[object_key_column_name] 
		,	[object_key_column_type] 
		,	[object_key_column_source]
		)
		SELECT 
			OC.[row_id] 
		,	ROW_NUMBER() OVER (PARTITION BY OC.[row_id] ORDER BY (SELECT NULL))
		,	O.[object_key_column_name] 
		,	O.[object_key_column_type] 
		,	O.[object_key_column_source] 
		FROM ', @as_object_keys_table_name, N' AS O
			INNER JOIN #object_class AS OC
				ON O.[object_class_name] = OC.[object_class_name]
		;'
	);
	
	IF @ai_debug_level > 0
		PRINT CONCAT(N'Executing the following in DSQL: ', @ls_sql);
	
	EXEC(@ls_sql);

	/*******************************************************************************
	Create new rows in [config].[object_class] using #object_class
	*******************************************************************************/
	INSERT INTO 
		[config].[object_class]
	(
		[object_class_id] 
	,	[object_class_name]
	,	[object_class_source]
	,	[object_class_source_alias]
	,	[table_schema_name]
	,	[table_name]
	,	[view_schema_name] 
	,	[view_name]
	)
	SELECT 
		[row_id]
	,	[object_class_name]
	,	[object_class_source]
	,	[object_class_source_alias]
	,	N'object'
	,	[object_class_name]
	,	[view_schema_name]
	,	[view_name]
	FROM 
		#object_class
	;

	IF @ai_debug_level > 1
	BEGIN
		SELECT '[config].[object_class] at the END of procedure';
		SELECT * FROM [config].[object_class];
	END;

	/*******************************************************************************
	Create new rows in [config].[object_class_metadata_key] using #metadata_keys
	*******************************************************************************/
	INSERT INTO [config].[object_class_metadata_key]
	(
		[object_class_id] 
	,	[metadata_key_column_id] 
	,	[metadata_key_column_name]
	,	[metadata_key_column_type]
	,	[metadata_key_column_source]
	)
	SELECT 
		[object_class_id] 
	,	[metadata_key_column_id] 
	,	[metadata_key_column_name]
	,	[metadata_key_column_type]
	,	[metadata_key_column_source]
	FROM #metadata_keys
	;

	IF @ai_debug_level > 1
	BEGIN
		SELECT '[config].[object_class_metadata_key] at the END of procedure';
		SELECT * FROM [config].[object_class_metadata_key];
	END;

	/*******************************************************************************
	Create new rows in [config].[object_class_metadata_key] using #object_keys
	*******************************************************************************/
	INSERT INTO [config].[object_class_object_key]
	(
		[object_class_id] 
	,	[object_key_column_id] 
	,	[object_key_column_name]
	,	[object_key_column_type]
	,	[object_key_column_source]
	)
	SELECT 
		[object_class_id] 
	,	[object_key_column_id] 
	,	[object_key_column_name]
	,	[object_key_column_type]
	,	[object_key_column_source]
	FROM #object_keys
	;

	IF @ai_debug_level > 1
	BEGIN
		SELECT '[config].[object_class_object_key] at the END of procedure';
		SELECT * FROM [config].[object_class_object_key];
	END;
END; 