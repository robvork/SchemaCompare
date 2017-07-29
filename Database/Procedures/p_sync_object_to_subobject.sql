DROP PROCEDURE IF EXISTS [config].[p_sync_object_to_subobject];
GO

CREATE PROCEDURE [config].[p_sync_object_to_subobject]
(
	@as_instance_name SYSNAME = NULL
,
	@ai_instance_id INT = NULL
,
	@as_database_name SYSNAME = NULL
,
	@ai_database_id INT = NULL
,	
	@as_object_class_name [config].[NAME] = NULL
,
	@ai_object_class_id INT = NULL
,	
	@as_subobject_class_name [config].[NAME] = NULL
,
	@ai_subobject_class_id INT = NULL
,
	@ai_debug_level INT = 1
)
AS
BEGIN
BEGIN TRY
	SET NOCOUNT ON;

	-- Declare local variables
	BEGIN
	DECLARE @ls_sql NVARCHAR(MAX); 
	DECLARE @ls_name_filter NVARCHAR(1000); 
	DECLARE @ls_error_msg NVARCHAR(MAX);
	DECLARE @ls_newline NCHAR(1); 
	DECLARE @ls_comma NCHAR(1);
	DECLARE @ls_single_quote NCHAR(1);
	DECLARE @ls_object_class_table_schema_name SYSNAME;
	DECLARE @ls_object_class_table_name SYSNAME;
	DECLARE @ls_subobject_class_table_schema_name SYSNAME;
	DECLARE @ls_subobject_class_table_name SYSNAME;
	
	DECLARE @ls_sql_merge_update_set_statements NVARCHAR(MAX);
	DECLARE @ls_sql_merge_insert_target_header NVARCHAR(MAX);
	DECLARE @ls_sql_merge_insert_source_header NVARCHAR(MAX);
	DECLARE @ls_key_column SYSNAME;
	DECLARE @ls_val_column SYSNAME;

	DECLARE @ls_sql_merge_target NVARCHAR(MAX);
	DECLARE @ls_sql_merge_source NVARCHAR(MAX);
	DECLARE @ls_sql_merge_matching_condition NVARCHAR(MAX);
	DECLARE @ls_sql_merge_when_matched NVARCHAR(MAX);
	DECLARE @ls_sql_merge_when_not_matched_by_target NVARCHAR(MAX);
	DECLARE @ls_sql_merge_when_not_matched_by_source NVARCHAR(MAX);

	DECLARE @ls_object_mapping_table_schema SYSNAME;
	DECLARE @ls_object_mapping_table_name SYSNAME;
	DECLARE @ls_object_mapping_query NVARCHAR(MAX);

	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  

	DECLARE @lb_input_table_has_required_columns BIT;

	END;

	-- Initialize local variables
	BEGIN
	SET @ls_newline = NCHAR(13); 
	SET @li_error_severity = 16;
	SET @li_error_state = 1;
	SET @ls_single_quote = N'''';
	SET @ls_comma = N',';
	END;

	-- Declare temp tables
	BEGIN
	DROP TABLE IF EXISTS #object_to_subobject_current;

	CREATE TABLE #object_to_subobject_current
	(
		[object_name] SYSNAME NOT NULL
	,	[object_id] INT NULL
	,	[subobject_name] SYSNAME NOT NULL
	,	[subobject_id] INT NULL
	,	PRIMARY KEY([object_name], [subobject_name])
	);

	END; 

	-- Validate/Set Instance in [config].[instance]
	BEGIN
	IF (@as_instance_name IS NULL AND @ai_instance_id IS NULL) 
		OR 
	   (@as_instance_name IS NOT NULL AND @ai_instance_id IS NOT NULL)
	BEGIN
		SET @ls_error_msg = N'Exactly one of @as_instance_name or @ai_instance_id must be specified';
		
		RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
	END;
	ELSE IF @as_instance_name IS NOT NULL
	BEGIN
		SET @ai_instance_id = 
		(
			SELECT [instance_id] 
			FROM [config].[instance] 
			WHERE [instance_name] = @as_instance_name
		);

		IF @ai_instance_id IS NULL
		BEGIN
			SET @ls_error_msg = 
			CONCAT 
			(
				@ls_single_quote
			,	@as_instance_name
			,	@ls_single_quote
			,	N' is not a recognized instance name'
			);

			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
		END;
	END; 
	ELSE IF @ai_instance_id IS NOT NULL
	BEGIN
		IF NOT EXISTS
		(
			SELECT * 
			FROM [config].[instance] 
			WHERE [instance_id] = @ai_instance_id
		)
		BEGIN
			SET @ls_error_msg = 
			CONCAT 
			(
				@ai_instance_id
			,	N' is not a valid instance ID'
			); 
		END; 
	END;
	END;

	-- Validate/Set Database in [config].[database]
	BEGIN
	IF (@as_database_name IS NULL AND @ai_database_id IS NULL) 
		OR 
	   (@as_database_name IS NOT NULL AND @ai_database_id IS NOT NULL)
	BEGIN
		SET @ls_error_msg = N'Exactly one of @as_database_name or @ai_database_id must be specified';
		
		RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
	END;
	ELSE IF @as_database_name IS NOT NULL
	BEGIN
		SET @ai_database_id = 
		(
			SELECT [database_id] 
			FROM [config].[database] 
			WHERE [database_name] = @as_database_name 
				  AND 
				  [instance_id] = @ai_instance_id
		);

		IF @ai_database_id IS NULL
		BEGIN
			SET @ls_error_msg = 
			CONCAT 
			(
				CONCAT 
				(
					@ls_single_quote
				,	@as_database_name
				,	@ls_single_quote
				) 
			,	N' is not a recognized database name for instance name '
			,	CONCAT 
				(
					@ls_single_quote
				,	@as_instance_name
				,	@ls_single_quote
				,	N' is not a recognized instance name'
				)
			);

			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
		END;
	END; 
	ELSE IF @ai_database_id IS NOT NULL
	BEGIN
		IF NOT EXISTS
		(
			SELECT * 
			FROM [config].[database] 
			WHERE [database_id] = @ai_database_id
				  AND 
				  [instance_id] = @ai_instance_id
		)
		BEGIN
			SET @ls_error_msg = 
			CONCAT 
			(
				@ai_database_id
			,	N' is not a valid database ID for instance ID '
			,	@ai_instance_id
			); 
		END; 
	END;
	END;

	-- Validate/Set Object Class in [config].[object_class]
	BEGIN
		IF (@as_object_class_name IS NULL AND @ai_object_class_id IS NULL) 
			OR 
		   (@as_object_class_name IS NOT NULL AND @ai_object_class_id IS NOT NULL)
		BEGIN
			SET @ls_error_msg = N'Exactly one of @as_object_class_name or @ai_object_class_id must be specified';
		
			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
		END;
		ELSE IF @as_object_class_name IS NOT NULL
		BEGIN
			SET @ai_object_class_id = 
			(
				SELECT [object_class_id] 
				FROM [config].[object_class] 
				WHERE [object_class_name] = @as_object_class_name
			);

			IF @ai_object_class_id IS NULL
			BEGIN
				SET @ls_error_msg = 
				CONCAT 
				(
					@ls_single_quote
				,	@as_object_class_name
				,	@ls_single_quote
				,	N' is not a recognized object class name'
				);

				RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
			END;
		END; 
		ELSE IF @ai_object_class_id IS NOT NULL
		BEGIN
			IF NOT EXISTS
			(
				SELECT * 
				FROM [config].[object_class] 
				WHERE [object_class_id] = @ai_object_class_id
			)
			BEGIN
				SET @ls_error_msg = 
				CONCAT 
				(
					@ai_object_class_id
				,	N' is not a valid object class ID'
				); 
			END; 
		END; 
	END;

	-- Validate/Set SubObject Class in [config].[object_class]
	BEGIN
		IF (@as_subobject_class_name IS NULL AND @ai_subobject_class_id IS NULL) 
			OR 
		   (@as_subobject_class_name IS NOT NULL AND @ai_subobject_class_id IS NOT NULL)
		BEGIN
			SET @ls_error_msg = N'Exactly one of @as_subobject_class_name or @ai_subobject_class_id must be specified';
		
			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
		END;
		ELSE IF @as_subobject_class_name IS NOT NULL
		BEGIN
			SET @ai_subobject_class_id = 
			(
				SELECT [object_class_id] 
				FROM [config].[object_class] 
				WHERE [object_class_name] = @as_subobject_class_name
			);

			IF @ai_subobject_class_id IS NULL
			BEGIN
				SET @ls_error_msg = 
				CONCAT 
				(
					@ls_single_quote
				,	@as_subobject_class_name
				,	@ls_single_quote
				,	N' is not a recognized object class name'
				);

				RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
			END;
		END; 
		ELSE IF @ai_subobject_class_id IS NOT NULL
		BEGIN
			IF NOT EXISTS
			(
				SELECT * 
				FROM [config].[object_class] 
				WHERE [object_class_id] = @ai_subobject_class_id
			)
			BEGIN
				SET @ls_error_msg = 
				CONCAT 
				(
					@ai_subobject_class_id
				,	N' is not a valid object class ID'
				); 
			END; 
		END; 
	END;

	-- Validate object and subobject are linked in [config].[object_to_subobject]
	-- If they're linked, set mapping table variables and the refresh query
	
	BEGIN
		IF NOT EXISTS
		(
			SELECT * 
			FROM [config].[object_to_subobject]
			WHERE [object_class_id] = @ai_object_class_id 
				  AND 
				  [subobject_class_id] = @ai_subobject_class_id
		)
		BEGIN
			SET @ls_error_msg = 'The chosen object and subobject classes are not linked in [config].[object_to_subobject]';
			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
		END; 

		ELSE
		BEGIN
			SELECT 
				@ls_object_mapping_table_schema = [mapping_table_schema]
			,	@ls_object_mapping_table_name = [mapping_table_name]
			-- replace the special {db} replace token with the name of the database we want to sync
			-- also remove any semicolons so we can use this in a CTE
			,	@ls_object_mapping_query = REPLACE(REPLACE([name_query], N'{db}', @as_database_name), N';', N'')
			FROM [config].[object_to_subobject]
			WHERE [object_class_id] = @ai_object_class_id 
					  AND 
				  [subobject_class_id] = @ai_subobject_class_id
			;
		END; 
	END;

	-- Get object and subobject schema and table names
	SELECT 
		@ls_object_class_table_schema_name = [table_schema_name]
	,	@ls_object_class_table_name = [table_name]
	FROM [config].[object_class]
	WHERE [object_class_id] = @ai_object_class_id

	SELECT 
		@ls_subobject_class_table_schema_name = [table_schema_name]
	,	@ls_subobject_class_table_name = [table_name]
	FROM [config].[object_class]
	WHERE [object_class_id] = @ai_subobject_class_id	
	
	-- Get current object and subobject names
	SET @ls_sql = 
	CONCAT 
	(
		N'
		WITH current_values AS
		(
		', @ls_object_mapping_query, N'
		)
		INSERT INTO #object_to_subobject_current
		  (
			[object_name] 
		  ,	[subobject_name]
		  )
		  SELECT 
			[object_name]
		  ,	[subobject_name] 
		  FROM
			current_values
		  ;
		'
	); 

	IF @ai_debug_level > 0
	BEGIN
		PRINT CONCAT(N'Executing the following in dynamic SQL:', @ls_newline, @ls_sql);
	END;

	IF @ai_debug_level > 1
	BEGIN
		SELECT 'current_values CTE';
		EXEC(@ls_object_mapping_query);
	END; 

	EXEC(@ls_sql);

	IF @ai_debug_level > 1
	BEGIN
		SELECT N'#object_to_subobject_current';
		SELECT [object_name], [subobject_name] FROM #object_to_subobject_current;
	END;

	-- get object and subobject ids from names. all names should correspond to exactly one row within an instance/database/object class combination
	SET @ls_sql = 
	CONCAT 
	(
		N'	UPDATE U2SC
			SET 
				U2SC.[object_id] = O.[object_id] 
		  ,		U2SC.[subobject_id] = SO.[object_id]
			FROM 
				#object_to_subobject_current AS U2SC
			INNER JOIN 
			',	QUOTENAME(@ls_object_class_table_schema_name), N'.', QUOTENAME(@ls_object_class_table_name), N' AS O
				ON  (U2SC.[object_name] = O.[name]) 
				AND (O.[instance_id] = ', @ai_instance_id, N')
				AND (O.[database_id] = ', @ai_database_id, N')
			INNER JOIN 
			',	QUOTENAME(@ls_subobject_class_table_schema_name), N'.', QUOTENAME(@ls_subobject_class_table_name), N' AS SO
				ON  (U2SC.[subobject_name] = SO.[name])
				AND (SO.[instance_id] = ', @ai_instance_id, N')
				AND (SO.[database_id] = ', @ai_database_id, N')
			;
		  '
	);

	IF @ai_debug_level > 0
	BEGIN
		PRINT CONCAT(N'Executing the following in dynamic SQL:', @ls_newline, @ls_sql);
	END;

	EXEC(@ls_sql);

	IF @ai_debug_level > 1
	BEGIN
		SELECT N'#object_to_subobject_current';
		SELECT 
			[object_name]
		,	[object_id]
		,	[subobject_name]
		,	[subobject_id] 
		FROM 
			#object_to_subobject_current;
	END;
	
	-- Validate that all object names correspond to an object_id by checking for any NULLs. If each name has an entry, there will be no NULLs
	IF EXISTS 
	(
		SELECT * 
		FROM #object_to_subobject_current
		WHERE [object_id] IS NULL 
			  OR 
			  [subobject_id] IS NULL
	)
	BEGIN 
		SET @ls_error_msg = 
		CONCAT(
			N'There is one or more object name which does not correspond to an object_id.', @ls_newline, 
			N'Run p_sync_object_class for the object class and subobject class and then run this procedure again.'
			  );

		IF @ai_debug_level > 1 
		BEGIN
			SELECT 'Invalid objects and subobjects in #object_to_subobject_current';

			SELECT 'Invalid object' AS [descr] 
			,	   [object_name] 
			FROM #object_to_subobject_current
			WHERE [object_id] IS NULL

			UNION ALL

			SELECT 'Invalid subobject' AS [descr]
			,	  [subobject_name] 
			FROM #object_to_subobject_current
			WHERE [subobject_id] IS NULL
		END; 
	END;

	/*
		The merge will have the following form:

		WITH merge_target AS
		(
			SELECT [object_id], [subobject_id] 
			FROM <object_to_subobject_schema>.<object_to_subobject_table>
		)
		MERGE INTO merge_target AS TGT
		
		USING #object_to_subobject_current AS SRC
		
		ON SRC.[object_id] = TGT.[object_id] 
		   AND 
		   SRC.[subobject_id] = TGT.[subobject_id]
		
		WHEN NOT MATCHED BY TARGET THEN
		INSERT ([object_id], [subobject_id])
		VALUES (SRC.[object_id], SRC.[subobject_id])
		
		WHEN NOT MATCHED BY SOURCE THEN 
		DELETE
		;
	*/

	-- Construct merge SQL
	SET @ls_sql_merge_target = 
	CONCAT 
	(
		N'WITH merge_target AS 
		(
			SELECT [object_id], [subobject_id] 
			FROM ', QUOTENAME(@ls_object_mapping_table_schema), N'.', QUOTENAME(@ls_object_mapping_table_name), N'
		)
		MERGE INTO merge_target AS TGT'
	);

	SET @ls_sql_merge_source = N'USING #object_to_subobject_current AS SRC'

	SET @ls_sql_merge_matching_condition = 
	CONCAT
	( 
		N'ON SRC.[object_id] = TGT.[object_id]', @ls_newline
	,	N'AND', @ls_newline
	,	N'SRC.[subobject_id] = TGT.[subobject_id]'
	);

	SET @ls_sql_merge_when_not_matched_by_target = 
	CONCAT 
	(
		N'WHEN NOT MATCHED BY TARGET THEN', @ls_newline 
	,	N'INSERT ([object_id], [subobject_id])', @ls_newline
	,	N'VALUES (SRC.[object_id], SRC.[subobject_id])'
	);

	SET @ls_sql_merge_when_not_matched_by_source =
	CONCAT 
	(	
		N'WHEN NOT MATCHED BY SOURCE THEN', @ls_newline
	,	N'DELETE'
	); 

	SET @ls_sql_merge_when_matched = N'-- WHEN MATCHED : nothing to update so omit'; 

	SET @ls_sql =  
	CONCAT 
	(
		@ls_sql_merge_target						, @ls_newline 
	,	@ls_sql_merge_source						, @ls_newline
	,	@ls_sql_merge_matching_condition			, @ls_newline 
	,	@ls_sql_merge_when_matched					, @ls_newline 
	,	@ls_sql_merge_when_not_matched_by_target	, @ls_newline 
	,	@ls_sql_merge_when_not_matched_by_source	, @ls_newline 
	,	N';'
	);

	IF @ai_debug_level > 0
	BEGIN
		PRINT CONCAT(N'Executing the following in dynamic SQL:', @ls_newline, @ls_sql);
	END;

	EXEC(@ls_sql);

	IF @ai_debug_level > 1
	BEGIN
		SET @ls_sql = CONCAT 
		(
			N'SELECT O.[object_id]	AS [object_id]
			,		 O.[name]		AS [object_name]
			,		 SO.[object_id] AS [subobject_id]
			,		 SO.[name]		AS [subobject_name]
			FROM ', QUOTENAME(@ls_object_mapping_table_schema), N'.', QUOTENAME(@ls_object_mapping_table_name), N' AS O2S
			INNER JOIN ', QUOTENAME(@ls_object_class_table_schema_name), N'.', QUOTENAME(@ls_object_class_table_name), N' AS O
				ON O2S.[object_id] = O.[object_id] 
			INNER JOIN ', QUOTENAME(@ls_subobject_class_table_schema_name), N'.', QUOTENAME(@ls_subobject_class_table_name), N' AS SO
				ON O2S.[subobject_id] = SO.[object_id]
			ORDER BY O.[name], SO.[name]	
			'
		);

		PRINT CONCAT(N'Executing the following in dynamic SQL:', @ls_newline, @ls_sql);

		EXEC(@ls_sql);
	END;
END TRY
BEGIN CATCH

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
	
	SET @li_error_severity = ERROR_SEVERITY(); 
	SET @li_error_state = ERROR_STATE();
	RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);

	RETURN 1;
END CATCH
END;
GO

IF 1 = 1
BEGIN
	EXEC [config].[p_sync_object_to_subobject]

	@as_instance_name = N'ASPIRING\SQL16'
--,
--	@ai_instance_id INT = NULL
,
	@as_database_name = N'WideWorldImporters'
--,
--	@ai_database_id INT = NULL
,	
	@as_object_class_name = N'table'
--,
--	@ai_object_class_id INT = NULL
,	
	@as_subobject_class_name = N'table_column'
--,
--	@ai_subobject_class_id INT = NULL
,
	@ai_debug_level = 2

END;