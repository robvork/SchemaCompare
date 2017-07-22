DROP PROCEDURE IF EXISTS [config].[p_initialize_object_to_subobject];
GO

CREATE PROCEDURE [config].[p_initialize_object_to_subobject]
(
	@ai_debug_level INT = 0
,	@as_input_table_name SYSNAME
)
AS
BEGIN
	BEGIN TRY
		DECLARE @ls_error_msg NVARCHAR(MAX);
		DECLARE @ls_sql NVARCHAR(MAX); 

		CREATE TABLE #object_to_subobject
		(
			[object_class_name] NVARCHAR(128) NOT NULL
		,	[object_class_id] INT NULL
		,	[subobject_class_name] NVARCHAR(128) NOT NULL
		,	[subobject_class_id] NVARCHAR(128) NULL
		);

		CREATE TABLE #object_name_to_id
		(
			[object_class_name] NVARCHAR(128) NOT NULL
		,	[object_class_id] INT NOT NULL
		);

		INSERT INTO #object_name_to_id
		(
			[object_class_name] 
		,	[object_class_id] 
		)
		SELECT 
			[object_class_name] 
		,	[object_class_id]
		FROM 
			[config].[object_class]
		;

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#object_name_to_id';
			SELECT * FROM #object_name_to_id;
		END;

		SET @ls_sql = 
		CONCAT 
		(
			N'
			INSERT INTO 
				#object_to_subobject
			(
				[object_class_name] 
			,	[subobject_class_name]
			)
			SELECT 
				[object_class_name]
			,	[subobject_class_name]
			FROM 
			 ', @as_input_table_name, N'
			;
			'
		); 

		IF @ai_debug_level > 0
			PRINT CONCAT(N'Executing the following in DSQL: ', @ls_sql);
	
		EXEC(@ls_sql);

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#object_to_subobject BEFORE updating IDs';
			SELECT * FROM #object_to_subobject;
		END;

		UPDATE O2SO
		SET O2SO.[object_class_id] = OID1.[object_class_id]
		,	O2SO.[subobject_class_id] = OID2.[object_class_id]
		FROM #object_to_subobject AS O2SO
			INNER JOIN #object_name_to_id AS OID1
				ON O2SO.[object_class_name] = OID1.[object_class_name]
			INNER JOIN #object_name_to_id AS OID2
				ON O2SO.[subobject_class_name] = OID2.[object_class_name]
		;

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#object_to_subobject AFTER updating IDs';
			SELECT * FROM #object_to_subobject;
		END;

		IF EXISTS 
		(
			SELECT * 
			FROM #object_to_subobject
			WHERE [object_class_id] IS NULL 
				  OR
				  [subobject_class_id] IS NULL
		)
		BEGIN
			IF @ai_debug_level > 1
			BEGIN
				SELECT 'The following object/subobject class names are invalid';
				
				SELECT 'object' AS [type_descr], [object_class_name] 
				FROM #object_to_subobject 
				WHERE [object_class_id] IS NULL 
							UNION 
				SELECT 'subobject' AS [type_descr], [subobject_class_name] 
				FROM #object_to_subobject
				WHERE [subobject_class_id] IS NULL
			END;

			SET @ls_error_msg = N'At least one object or subobject class name was invalid. See debug table output for details';
			RAISERROR(@ls_error_msg, 16, 1);
		END; 

		INSERT INTO 
			[config].[object_to_subobject]
		(
			[object_class_id]
		,	[subobject_class_id]
		)
		SELECT 
			[object_class_id]
		,	[subobject_class_id] 
		FROM 
			#object_to_subobject
		;

	END TRY
	BEGIN CATCH
		SET @ls_error_msg = ERROR_MESSAGE();
		RAISERROR(@ls_error_msg, 16, 1);
	END CATCH
END;