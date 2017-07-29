DROP PROCEDURE IF EXISTS [config].[p_initialize_object_class];
GO

CREATE PROCEDURE [config].[p_initialize_object_class]
(
	@ai_debug_level INT = 0
,	@as_input_table_name SYSNAME
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
	,	object_class_source_object_id_column SYSNAME NOT NULL
	,	view_schema_name SYSNAME NOT NULL
	,	view_name SYSNAME NOT NULL
	);

	SET @ls_sql = CONCAT 
	(
		N'
		INSERT INTO #object_class 
		(
			row_num
		,	object_class_name 
		,	object_class_source
		,	object_class_source_alias 
		,	object_class_source_object_id_column
		,	view_schema_name
		,	view_name
		)
		SELECT 
			ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		,	I.[object_class_name] 
		,	I.[object_class_source]
		,	I.[object_class_source_alias]
		,	I.[object_class_source_object_id_column]
		,	I.[view_schema_name]
		,	I.[view_name] 
		FROM ', @as_input_table_name, N' AS I
		;'
	);
	
	IF @ai_debug_level > 0
		PRINT CONCAT(N'Executing the following in DSQL: ', @ls_sql);
	
	EXEC(@ls_sql);
	
	IF @ai_debug_level > 1
	BEGIN
		SELECT '#object_class BEFORE setting IDs';
		SELECT * FROM #object_class; 
	END;
	
	/*******************************************************************************
	Generate a new object_class_id for each row of #object_class. 
	Set #object_class.[row_num] to these values
	*******************************************************************************/
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
	Create new rows in [config].[object_class] using #object_class
	*******************************************************************************/
	INSERT INTO 
		[config].[object_class]
	(
		[object_class_id] 
	,	[object_class_name]
	,	[object_class_source]
	,	[object_class_source_alias]
	,	[object_class_source_object_id_column]
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
	,	[object_class_source_object_id_column]
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

END; 