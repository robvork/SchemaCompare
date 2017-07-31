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
		,	object_class_property_is_enabled BIT NOT NULL 
		,	object_class_property_is_metadata_key BIT NOT NULL
		,	object_class_property_is_object_key BIT NOT NULL
		,	PRIMARY KEY([object_class_id], [object_class_property_id])
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
		,	[object_class_property_is_metadata_key]
		,	[object_class_property_is_object_key]
		)
		-- All object classes have standard metadata keys [instance_id] and [database_id]
		SELECT 
			OC.[object_class_id]
		,	standard_metadata_keys.[object_class_property_id]
		,	standard_metadata_keys.[object_class_property_name]
		,	standard_metadata_keys.[object_class_property_type]
		,	0 -- doesn't have length
		,	NULL -- NULL length
		,	0 -- is not nullable
		,	1 -- enabled 
		,   1 -- is a metadata key
		,	0 -- is not an object key
		FROM 
			[config].[object_class] AS OC
			CROSS JOIN 
			(
				SELECT [object_class_property_name] 
				,	   [object_class_property_id]
				,	   [object_class_property_type] 
				FROM 
				(
					VALUES 
					('instance_id', 1, N'INT')
				,	('database_id', 2, N'INT')
				) AS standard_metadata_keys ([object_class_property_name], [object_class_property_id], [object_class_property_type])
			)  AS standard_metadata_keys ([object_class_property_name], [object_class_property_id], [object_class_property_type])

		UNION ALL
		-- All object classes have a set of 1 or more custom metadata keys
		SELECT 
			OC.[object_class_id]
		,	2 + ROW_NUMBER() OVER (
									PARTITION BY OC.[object_class_id]
									ORDER BY (SELECT NULL)
								  ) 
		,	custom_metadata_keys.[object_class_property_name]
		,	custom_metadata_keys.[object_class_property_type]
		,	0 -- doesn't have length
		,	NULL -- NULL length
		,	0 -- is not nullable
		,	1 -- enabled 
		,   1 -- is a metadata key
		,	0 -- is not an object key
		FROM [config].[object_class] AS OC 
			CROSS APPLY 
			(
				SELECT 
					MK.[metadata_key_column_name]
				,	MK.[metadata_key_column_type]
				FROM 
					[config].[object_class_metadata_key] AS MK
				WHERE 
					MK.[object_class_id] = OC.[object_class_id]
			) AS custom_metadata_keys([object_class_property_name], [object_class_property_type])
		WHERE custom_metadata_keys.[object_class_property_name] NOT IN (N'instance_id', 'database_id')

		UNION ALL 
		-- All object classes have a set of 1 or more custom object keys
		SELECT 
			OC.[object_class_id]
		/* The property id for the object keys start at 
			(# of standard metadata keys)
						+
			(# of custom metadata keys)
					    + 
			 1

			The number of standard keys is the 2 for each object class, so we have the expression
			2 + (# of custom metadata keys). The subquery below counts the number of such keys. 
			Finally, with the first two terms of the expression, we number beginning at 1 and increase
			for as many custom object keys as are present for each object class. ROW_NUMBER()
			accomplishes this numbering exactly.
		*/
		,	2 + 
			(
				SELECT COUNT(*) 
				FROM [config].[object_class_metadata_key] AS MK
				WHERE MK.[object_class_id] = OC.[object_class_id]
					  AND 
					  MK.[metadata_key_column_name] NOT IN (N'instance_id', 'database_id')
			) + 
			ROW_NUMBER() OVER (PARTITION BY OC.[object_class_id] 
							   ORDER BY (SELECT NULL) 
							  )
		,	custom_object_keys.[object_class_property_name]
		,	custom_object_keys.[object_class_property_type]
		,	0 -- doesn't have length
		,	NULL -- NULL length
		,	0 -- is not nullable
		,	1 -- enabled 
		,   0 -- is not a metadata key
		,	1 -- is an object key
		FROM [config].[object_class] AS OC
		CROSS APPLY 
		(
			SELECT 
				OK.[object_key_column_name]
			,	OK.[object_key_column_type]
			FROM [config].[object_class_object_key] AS OK
			WHERE OK.[object_class_id] = OC.[object_class_id]
				  AND 
				  OK.[object_key_column_name] NOT IN (N'instance_id', 'database_id')
		) AS custom_object_keys ([object_class_property_name], [object_class_property_type])

		UNION ALL

		-- The remaining properties are non-key columns which come from all the columns of the object class's
		--	source catalog view, excluding any columns which have the same names as metadata or object keys 
		--	as defined above
		SELECT 
			OC.[object_class_id]
		-- The expression below is the expression from the previous result set
		-- with the number of object key rows added, where this number is obtained
		-- from [config].[object_class_object_key] but otherwise in the same manner as for metadata key
		,	2 + 
			(
				SELECT COUNT(*) 
				FROM [config].[object_class_metadata_key] AS MK
				WHERE MK.[object_class_id] = OC.[object_class_id]
					  AND 
					  MK.[metadata_key_column_name] NOT IN (N'instance_id', 'database_id')
			) +
			(
				SELECT COUNT(*)
				FROM [config].[object_class_object_key] AS OK
				WHERE OK.[object_class_id] = OC.[object_class_id]
					  AND 
					  OK.[object_key_column_name] NOT IN (N'instance_id', 'database_id')
			) + 
			ROW_NUMBER() OVER 
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
		,	0 -- not a metadata key
		,	0 -- not a object key
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
		-- ignore any view columns which have the same name as the keys specified above
		WHERE VC.[view_column_name] NOT IN 
		(
			SELECT [standard_metadata_key_name]
			FROM 
			(
				VALUES 
				('instance_id')
			,	('database_id')
			) AS standard_metadata_keys([standard_metadata_key_name])

			UNION ALL 

			SELECT [metadata_key_column_name] AS [custom_metadata_key_name]
			FROM [config].[object_class_metadata_key] AS MK
			WHERE MK.[object_class_id] = OC.[object_class_id]

			UNION ALL

			SELECT [object_key_column_name] AS [custom_object_key_name] 
			FROM [config].[object_class_object_key] AS OK
			WHERE OK.[object_class_id] = OC.[object_class_id]
		)
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
		,	[object_class_property_is_metadata_key]
		,	[object_class_property_is_object_key]
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
		,	[object_class_property_is_metadata_key]
		,	[object_class_property_is_object_key]
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

