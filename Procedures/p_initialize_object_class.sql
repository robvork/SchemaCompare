DROP PROCEDURE IF EXISTS [config].[p_initialize_object_class];
GO

CREATE PROCEDURE [config].[p_initialize_object_class]
AS
BEGIN
	DECLARE @li_num_ids_needed INT;

	DROP TABLE IF EXISTS #object_class_ids; 

	CREATE TABLE #object_class_ids
	(
		[row_number] INT NULL
	,	[object_class_id] INT NOT NULL
	);

	DROP TABLE IF EXISTS #object_class;

	CREATE TABLE #object_class
	(
		object_class_id INT NOT NULL
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
		object_class_id
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
	
	SELECT * FROM #object_class; 

	SET @li_num_ids_needed = 
	(
		SELECT COUNT(*)
		FROM #object_class
	);

	INSERT INTO #object_class_ids
	EXECUTE [config].[p_get_next_id] 
		@as_schema_name = 'config'
	,	@as_table_name = 'object_class'
	,	@ai_num_ids_needed = @li_num_ids_needed
	;

	UPDATE #object_class_ids 
	SET [row_number] = ROW_NUMBER() OVER (ORDER BY (SELECT NULL))

	SELECT * FROM #object_class_ids;
		

END; 