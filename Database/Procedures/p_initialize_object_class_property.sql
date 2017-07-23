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
				WHEN C.[user_type_id] IN (
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
		,	[object_class_property_is_enabled]
		)
		-- Primary key of each object class table
		-- server_id, database_id, object_id
		SELECT 
			OC.[object_class_id]
		,	id_props.[object_class_property_id]
		,	id_props.[object_class_property_name]
		,	'INT'
		,	0 -- doesn't have length
		,	NULL -- NULL length
		,	0 -- is not nullable
		,	0 -- is not enabled for comparison because the primary key is an arbitrarily assigned SchemaCompare entity
				-- thus differences in values are not meaningful.
		FROM 
			[config].[object_class] AS OC
			CROSS JOIN 
			(
				SELECT [object_class_property_name] 
				,	   [object_class_property_id]
				FROM 
				(
					VALUES 
					('instance_id', 1)
				,	('database_id', 2)
				,	('object_id'  , 3)
				) AS id_props ([object_class_property_name], [object_class_property_id])
			)  AS id_props ([object_class_property_name], [object_class_property_id])

		UNION ALL

		-- all objects have a textual property 'name' for which (server_id, database_id, name) 
			-- an alterate key for the table. This name is to be preferred in comparisons 
			-- because it is the key data that comes from the original db, unlike the IDs which are generated
			-- within schemacompare
		SELECT 
			OC.[object_class_id]
		,	4 -- assign the next available object_property_id 
		,	'name'
		,	'SYSNAME'
		,	0 -- doesn't have length
		,	NULL -- undefined length
		,	0 -- is not nullable since it is part of a candidate key
		,	1 -- enabled. the 'name' is the minimal set of attributes for comparison.
		FROM 
			[config].[object_class] AS OC

		UNION ALL 

		SELECT 
			OC.[object_class_id]
		-- number each property arbitrarily separately for each object class
		-- start the numbering at 2 so that property_id = 1 is always parent_object_id
		,	4 + ROW_NUMBER() OVER 
			(
				PARTITION BY OC.[object_class_id]
				ORDER BY (SELECT NULL)
			)	
		,	VC.[view_column_name]
		,	VC.[view_column_type_name]
		,	VC.[view_column_type_has_length]
		,	VC.[view_column_type_length]
		,	VC.[view_column_is_nullable]
		--	By default, disable all columns except parent_object_id and name
		,	0
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
		-- ignore any occurrences of the first 4 columns in the system views
		WHERE (VC.[view_column_name] NOT IN ('server_id', 'database_id', 'object_id', 'name'))
		;

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
		DECLARE @ls_newline NCHAR = NCHAR(13);
		SET @ls_error_msg = 
		CONCAT 
		(
			'{', @ls_newline 		 
		,		 'ERROR MESSAGE: ', ERROR_MESSAGE(), @ls_newline
		,		 'ERROR PROCEDURE: ', ERROR_PROCEDURE(), @ls_newline 
		,		 'ERROR LINE: ', ERROR_LINE(), @ls_newline
		,		 'ERROR SEVERITY: ', ERROR_SEVERITY(), @ls_newline 
		,		 'ERROR STATE: ', ERROR_STATE(), @ls_newline
		,	'}'
		);
		RAISERROR(@ls_error_msg, 16, 1);
	END CATCH;
END;

