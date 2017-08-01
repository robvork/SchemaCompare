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
		SET O2SO.[object_class_id] = OC1.[object_class_id]
		,	O2SO.[subobject_class_id] = OC2.[object_class_id]
		FROM #object_to_subobject AS O2SO
			INNER JOIN [config].[object_class] AS OC1
				ON O2SO.[object_class_name] = OC1.[object_class_name]
			INNER JOIN [config].[object_class] AS OC2
				ON O2SO.[subobject_class_name] = OC2.[object_class_name]
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

		-- Insert the parent metadata keys into their children
		INSERT INTO
			[config].[object_class_metadata_key] 
		(
			[object_class_id] 
		,	[metadata_key_column_id] 
		,	[metadata_key_column_name] 
		,	[metadata_key_column_type]
		,	[metadata_key_column_source]
		,	[is_parent_metadata_key]
		)
		SELECT 
			-- child object class id
			O2SO.[subobject_class_id]
		,	2 + (
				SELECT COUNT(*) 
				FROM [config].[object_class_metadata_key] AS MK2
				WHERE MK2.[object_class_id] = O2SO.[subobject_class_id]
			) + 
			ROW_NUMBER () OVER (ORDER BY (SELECT NULL))
		,	MK.[metadata_key_column_name]
		,	MK.[metadata_key_column_type] 
		/* this one requires a little explanation. we enforce that the parent and child
		   object have in common the columns which form the metadata key of the parent class.
		   we also use a generic replace token {alias} in the object class source.
		   therefore, we can reuse the parent column source in the child column source without alteration.

		   for example, the 'table column' source includes an [object_id] column
		   which references the table the column belongs to. if the alias we use
		   is C, then C.[object_id] is the column which is the metadata key to the parent object
		   class source.

		   within the parent object class 'table', we also have an [object_id] which forms the custom
		   non-parent metadata key for table. If we use the alias T, then this column's source
		   is T.[object_id].

		   now, replacing C and T with the generic {alias} which we later substitute with the 
		   data-driven object class source alias (see [config].[object_class]), we obtain
		   {alias}.[object_id] in the first case, and {alias}.[object_id] in the second.
		   these are the same expression, so we use the parent's column source verbatim
		   in the child.
		*/
		,	MK.[metadata_key_column_source] 
		,	1
		FROM [config].[object_to_subobject] AS O2SO
		INNER JOIN [config].[object_class_metadata_key] AS MK
		-- join on parent object class id
			ON O2SO.[object_class_id] = MK.[object_class_id]

	END TRY
	BEGIN CATCH
		SET @ls_error_msg = ERROR_MESSAGE();
		RAISERROR(@ls_error_msg, 16, 1);
	END CATCH
END;