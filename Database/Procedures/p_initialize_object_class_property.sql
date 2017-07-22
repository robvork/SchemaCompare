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
			object_class_id INT NOT NULL
		,	object_class_property_id INT NOT NULL
		,	object_class_property_name NVARCHAR(128) NOT NULL
		,	object_class_property_type_name SYSNAME NOT NULL
		,	object_class_property_is_nullable BIT NOT NULL
		,	object_class_property_has_length BIT NOT NULL
		,	object_class_property_length INT NULL
		,	object_class_property_is_enabled BIT NOT NULL DEFAULT 0
		);

		CREATE TABLE #view_column
		(
			view_schema_id INT NOT NULL
		,	view_object_id INT NOT NULL
		,	view_column_name NVARCHAR(128) NOT NULL
		,	view_column_type_name NVARCHAR(128) NOT NULL
		,	view_column_type_has_length BIT NOT NULL
		,	view_column_type_length INT NULL
		,	view_column_is_nullable NVARCHAR(128) NOT NULL
		,	PRIMARY KEY(view_schema_id, view_object_id, view_column_name)
		);

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
		
		WITH object_class_views([schema_id], [object_id]) AS 
		(
			SELECT DISTINCT 
				V.[schema_id] 
			,	V.[object_id] 
			FROM 
				[config].[object_class] AS OC
			INNER JOIN sys.all_views AS V
				ON SCHEMA_ID(OC.[view_schema_name]) = V.[schema_id] 
				AND OC.[view_name] = V.[name]		
		)
		INSERT INTO #view_column
		(
			[view_schema_id]
		,	[view_object_id]
		,	[view_column_name]
		,	[view_column_type_name]
		,	[view_column_type_has_length]
		,	[view_column_type_length]
		,	[view_column_is_nullable]
		)
		SELECT 
			V.[schema_id]
		,	V.[object_id]
		,	C.[name] 
		,	T.[name]
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
				WHEN C.[user_type_id] IN (@li_system_type_id_nchar, @li_system_type_id_nvarchar)
					THEN C.[max_length]/2
				WHEN C.[user_type_id] IN (@li_system_type_id_char, @li_system_type_id_varchar)
					THEN C.[max_length] 
				ELSE 
					NULL 
			END 
		,	C.[is_nullable]
		FROM object_class_views AS V 
			INNER JOIN sys.all_columns AS C
				ON V.[object_id] = C.[object_id]
			INNER JOIN sys.types AS T
				ON C.[user_type_id] = T.[user_type_id]
		;

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#view_property';
			SELECT * FROM #view_column;
		END;

		INSERT INTO 
			#object_class_property
		(
			[object_class_id]
		,	[object_class_property_id]
		,	[object_class_property_name]
		,	[object_class_property_type_name]
		,	[object_class_property_has_length]
		,	[object_class_property_length]
		,	[object_class_property_is_nullable]
		)
		SELECT 
			OC.[object_class_id]
		,	ROW_NUMBER() OVER 
			(
				PARTITION BY OC.[object_class_id]
				ORDER BY (SELECT NULL)
			)	
		,	VC.[view_column_name]
		,	VC.[view_column_type_name]
		,	VC.[view_column_type_has_length]
		,	VC.[view_column_type_length]
		,	VC.[view_column_is_nullable]
		FROM 
			[config].[object_class] 
			AS OC
		INNER JOIN 
			sys.all_views 
			AS V
				ON SCHEMA_ID(OC.[view_schema_name]) = V.[schema_id]
				   AND 
				   OC.[view_name] = V.[name]
		INNER JOIN 
			#view_column
			AS VC 
				ON V.[schema_id] = VC.[view_schema_id]
				   AND 
				   V.[object_id] = VC.[view_object_id]
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
		,	[object_class_property_type_name]
		,	[object_class_property_has_length]
		,	[object_class_property_length]
		,	[object_class_property_is_nullable]
		,	[object_class_property_is_enabled]
		)
		SELECT 
			[object_class_id]
		,	[object_class_property_id]
		,	[object_class_property_name]
		,	[object_class_property_type_name]
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

