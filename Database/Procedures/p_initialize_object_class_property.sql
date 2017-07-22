DROP PROCEDURE IF EXISTS [config].[p_initialize_object_class_property];
GO

CREATE PROCEDURE [config].[p_initialize_object_class_property]
(
	@ai_debug_level INT = 0
)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;
		DECLARE @li_system_type_id_nchar INT;
		DECLARE @li_system_type_id_nvarchar INT;
		DECLARE @li_system_type_id_char INT;
		DECLARE @li_system_type_id_varchar INT;
		DECLARE @ls_error_msg NVARCHAR(MAX);

		EXEC [config].[p_initialize_next_id]
			@as_schema_name = 'config' 
		,	@as_table_name = 'object_class_property'
		;

		DROP TABLE IF EXISTS #object_class_property;

		CREATE TABLE #object_class_property
		(
			row_num INT NOT NULL PRIMARY KEY
		,	row_id INT NULL
		,	object_class_id INT NOT NULL
		,	object_class_property_system_type_id INT NOT NULL
		,	object_class_property_name NVARCHAR(128) NOT NULL
		,	object_class_property_is_nullable NVARCHAR(128) NOT NULL
		,	object_class_property_has_length BIT NOT NULL
		,	object_class_property_length INT NULL
		,	object_class_property_is_enabled BIT NOT NULL DEFAULT 1
		);

		CREATE TABLE #view
		(
			[view_object_id] INT NOT NULL PRIMARY KEY
		,	[schema_name] SYSNAME NOT NULL
		,	[view_name] SYSNAME NOT NULL
		);

		CREATE TABLE #view_property
		(
			view_object_id INT NOT NULL 
		,	view_property_system_type_id INT NOT NULL
		,	view_property_name NVARCHAR(128) NOT NULL
		,	view_property_is_nullable NVARCHAR(128) NOT NULL
		,	view_property_has_length BIT NOT NULL
		,	view_property_length INT NULL
		,	PRIMARY KEY(view_object_id, view_property_name)
		);

		CREATE TABLE #object_class_to_view
		(
			object_class_id INT NOT NULL
		,	view_object_id INT NOT NULL
		); 

		CREATE TABLE #system_type_to_schema_compare_type
		(
			system_type_id INT NOT NULL
		,	schema_compare_type_id INT NOT NULL UNIQUE
		,	PRIMARY KEY(system_type_id, schema_compare_type_id)
		);
		/*
			sys.tables
			sys.views
			sys.columns
			sys.procedures
			sys.objects
			sys.parameters
		*/

		SET @li_system_type_id_nchar = 
		(
			SELECT [system_type_id]
			FROM sys.types 
			WHERE [name] = 'NCHAR'
		);
		SET @li_system_type_id_nvarchar = 
		(
			SELECT [system_type_id]
			FROM sys.types 
			WHERE [name] = 'NVARCHAR'
		);
		SET @li_system_type_id_char = 
		(
			SELECT [system_type_id]
			FROM sys.types 
			WHERE [name] = 'CHAR'
		);
		SET @li_system_type_id_varchar = 
		(
			SELECT [system_type_id]
			FROM sys.types 
			WHERE [name] = 'VARCHAR'
		);
		
		WITH views_to_insert AS
		(
			SELECT [schema_name], [view_name] 
			FROM 
			(
				VALUES 
				('sys', 'tables')
			,	('sys', 'views')
			,	('sys', 'procedures')
			,	('sys', 'columns')
			,	('sys', 'parameters')
			,	('sys', 'types')
			) AS view_names_values ([schema_name], [view_name])
		)
		INSERT INTO #view
		(
			[view_object_id]
		,	[schema_name]
		,	[view_name]
		)
		SELECT 
			V.[object_id] 
		,	VI.[schema_name] 
		,	VI.[view_name] 
		FROM views_to_insert AS VI 
			 INNER JOIN sys.all_views AS V
				ON VI.[view_name] = V.[name]
		WHERE V.[schema_id] = SCHEMA_ID('sys')
		; 

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#view';
			SELECT * FROM #view; 
		END; 

		INSERT INTO #view_property
		(
			[view_object_id]
		,	[view_property_name]
		,	[view_property_system_type_id]
		,	[view_property_is_nullable]
		,	[view_property_has_length]
		,	[view_property_length]
		)
		SELECT 
			V.[view_object_id]
		,	C.[name] 
		,	C.[system_type_id]
		,	C.[is_nullable]
		,	CASE 
				WHEN C.[system_type_id] IN (
												@li_system_type_id_nchar
										   ,	@li_system_type_id_nvarchar
										   ,	@li_system_type_id_char 
										   ,	@li_system_type_id_varchar 
										   )
					THEN 1
				ELSE 
						 0
			END
		,	CASE 
				WHEN C.[system_type_id] IN (@li_system_type_id_nchar, @li_system_type_id_nvarchar)
					THEN C.[max_length]/2
				WHEN C.[system_type_id] IN (@li_system_type_id_char, @li_system_type_id_varchar)
					THEN C.[max_length] 
				ELSE 
					NULL 
			END 
		FROM #view AS V 
			INNER JOIN sys.all_columns AS C
				ON V.[view_object_id] = C.[object_id]
		;

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#view_property';
			SELECT * FROM #view_property;
		END;

		WITH object_class_name_to_view_name AS
		(
			SELECT [object_class_name]
			,	   [schema_name] 
			,	   [view_name] 
			FROM
			(
				VALUES
				('table', 'sys', 'tables') 
			,	('view', 'sys', 'views')
			,	('table_column', 'sys', 'columns')
			,	('view_column', 'sys', 'columns')
			,	('uddt', 'sys', 'types')
			,	('proc', 'sys', 'procedures')
			,	('proc_param', 'sys', 'parameters')
			,	('func', 'sys', 'objects')
			,	('func_param', 'sys', 'parameters')
			) AS object_class_name_to_view_name_values 
				 (
					[object_class_name]
				 ,  [schema_name] 
				 ,	[view_name] 
				 )
		)
		INSERT INTO #object_class_to_view
		(
			[object_class_id]
		,	[view_object_id]
		)
		SELECT 
			OC.[object_class_id]
		,	V.[view_object_id] 
		FROM object_class_name_to_view_name AS OCN2VN
			INNER JOIN [config].[object_class] AS OC
				ON OCN2VN.object_class_name = OC.object_class_name
			INNER JOIN #view AS V
				ON OCN2VN.[schema_name] = V.[schema_name]
				   AND 
				   OCN2VN.[view_name] = V.[view_name]
		;

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#object_class_to_view';
			SELECT * FROM #object_class_to_view;
		END; 

		INSERT INTO #system_type_to_schema_compare_type
		(
			[system_type_id]
		,	[schema_compare_type_id]
		)
		SELECT 
			T.[system_type_id] 
		,	ST.[system_type_id] 
		FROM 
			[config].[system_type] 
				AS ST 
		INNER JOIN 
			sys.types 
				AS T 
				ON ST.[system_type_name] = T.[name] 
		;

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#system_type_to_schema_compare_type';
			SELECT * FROM #system_type_to_schema_compare_type;
		END; 

		INSERT INTO #object_class_property
		(
			[row_num]
		,	[object_class_id]
		,	[object_class_property_name]
		,	[object_class_property_system_type_id]
		,	[object_class_property_has_length]
		,	[object_class_property_length]
		,	[object_class_property_is_nullable]
		)
		SELECT 
			ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		,	OC.[object_class_id]
		,	VP.[view_property_name]
		,	T.[schema_compare_type_id]
		,	VP.view_property_has_length
		,	VP.view_property_length
		,	VP.view_property_is_nullable
		FROM 
			[config].[object_class] 
				AS OC
		INNER JOIN 
			#object_class_to_view 
				AS OC2V
				ON OC.object_class_id = OC2V.object_class_id
		INNER JOIN 
			#view_property
				AS VP
				ON OC2V.view_object_id = VP.view_object_id
		INNER JOIN 
			#system_type_to_schema_compare_type 
				AS T
				ON VP.view_property_system_type_id = T.system_type_id
		;
		
		IF @ai_debug_level > 1
		BEGIN
			SELECT '#object_class_property BEFORE ID assignment';
			SELECT * FROM #object_class_property;
		END; 

		EXEC [config].[p_get_next_id]
			@as_schema_name = 'config' 
		,	@as_table_name = 'object_class_property' 
		,	@as_work_table_name = '#object_class_property'
		;

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#object_class_property AFTER ID assignment';
			SELECT * FROM #object_class_property;
		END; 

		INSERT INTO 
			[config].[object_class_property]
		(
			[object_class_id]
		,	[object_class_property_id] 
		,	[object_class_property_name]
		,	[object_class_property_system_type_id]
		,	[object_class_property_has_length]
		,	[object_class_property_length]
		,	[object_class_property_is_nullable]
		,	[object_class_property_is_enabled]
		)
		SELECT 
			[object_class_id]
		,	[row_id]
		,	[object_class_property_name]
		,	[object_class_property_system_type_id]
		,	[object_class_property_has_length]
		,	[object_class_property_length]
		,	[object_class_property_is_nullable]
		,	[object_class_property_is_enabled]
		FROM
			#object_class_property
		;

	END TRY
	BEGIN CATCH
		SET @ls_error_msg = 
			CONCAT( ERROR_MESSAGE(), NCHAR(13)
				  ,'Error Line: ', ERROR_LINE(), NCHAR(13)
				  ,'Error Procedure: ', ERROR_PROCEDURE()
				  );
		RAISERROR(@ls_error_msg, 16, 1);
	END CATCH;
END;

--SELECT * FROM [config].[object_class]
--SELECT * FROM [config].[system_type]
-- SELECT * FROM [config].[object_class_property]

-- EXEC [config].[p_initialize_object_class_property]
