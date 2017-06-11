DROP PROCEDURE IF EXISTS [config].[p_initialize_object_class];
GO

CREATE PROCEDURE [config].[p_initialize_object_class]
(
	@ai_debug_level INT = 0
)
AS
BEGIN
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
	,	object_class_is_schema_class BIT NOT NULL
	);

	WITH object_classes AS
	(
		SELECT 
			[object_class_name] 
		,	[object_class_source]
		,	[object_class_source_alias]
		,	[object_class_is_schema_class] 
		FROM 
		(
			VALUES 
			(
					'table'
				,	'sys.tables AS <alias>'
				,	'T'
				,	1
			)
			,
			(
					'table_column'
				,	'sys.columns AS <alias> WHERE EXISTS 
					(
						SELECT * 
						FROM sys.tables 
						WHERE sys.tables.[object_id] = <alias>.[object_id]
					)'
				,	'C'
				,	0
			)
			,
			(
					'view'
				,	'sys.views AS <alias>'
				,	'V'
				,	1
			)
			,
			(
					'view_column'
				,	'sys.columns AS <alias> WHERE EXISTS 
					(
						SELECT * 
						FROM sys.views 
						WHERE sys.views.[object_id] = <alias>.[object_id]
					)'
				,	'C'
				,	0
			)
			,
			(
					'uddt'
				,	'sys.types AS <alias>'
				,	'T'
				,	1
			)
			,
			(
					'proc'
				,	'sys.procedures AS <alias>'
				,	'P'
				,	1
			)
			,
			(
					'proc_param'
				,	'sys.parameters AS <alias> WHERE EXISTS
					(
						SELECT * 
						FROM sys.procedures 
						WHERE sys.procedures.[object_id] = <alias>.[object_id]
					)'
				,	'P'
				,	0
			)
			,
			(
					'function'
				,	'sys.object AS <alias> WHERE [type] = N''FN'''
				,	'F'
				,	1
			)
			,
			(
					'function_param'
				,	'sys.parameters AS <alias> WHERE EXISTS
					(
						SELECT * 
						FROM sys.objects 
						WHERE sys.objects.[object_id] = <alias>.[object_id] 
							  AND 
							  sys.objects.[type] = ''FN''
					)'
				,	'P'
				,	0
			)
		)  AS object_class_values
			(
				[object_class_name] 
			,	[object_class_source]
			,	[object_class_source_alias]
			,	[object_class_is_schema_class] 
			)
	)
	INSERT INTO #object_class 
	(
		row_num
	,	object_class_name 
	,	object_class_source
	,	object_class_source_alias 
	,	object_class_is_schema_class 
	)
	SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
	,	[object_class_name] 
	,	[object_class_source]
	,	[object_class_source_alias]
	,	[object_class_is_schema_class] 
	FROM object_classes
	
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
	,	[object_class_is_schema_class]
	)
	SELECT 
		[row_id]
	,	[object_class_name]
	,	[object_class_source]
	,	[object_class_source_alias]
	,	[object_class_is_schema_class]
	FROM 
		#object_class
	;

	IF @ai_debug_level > 1
	BEGIN
		SELECT '[config].[object_class] at the END of procedure';
		SELECT * FROM [config].[object_class];
	END;

END; 