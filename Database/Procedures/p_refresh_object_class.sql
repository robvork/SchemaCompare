DROP PROCEDURE IF EXISTS [config].[p_refresh_object_class];
GO

CREATE PROCEDURE [config].[p_refresh_object_class]
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
	@ai_debug_level INT = 0
)
AS
/*
	Refresh just the selected object class without any recursion
*/
BEGIN
BEGIN TRY
	SET NOCOUNT ON;

	-- Declare local variables
	BEGIN
	DECLARE @ls_sql NVARCHAR(MAX); 
	DECLARE @ls_name_filter NVARCHAR(1000); 
	DECLARE @ls_error_msg NVARCHAR(MAX);
	DECLARE @ls_newline NCHAR(1); 
	DECLARE @ls_single_quote NCHAR(1);
	DECLARE @ls_object_class_table_schema_name SYSNAME;
	DECLARE @ls_object_class_table_name SYSNAME;
	DECLARE @ls_object_class_source NVARCHAR(MAX);
	DECLARE @ls_object_class_source_alias NVARCHAR(10);
	DECLARE @ls_object_class_current_values_table_name SYSNAME;

	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  

	END;

	-- Initialize local variables
	BEGIN
	SET @ls_newline = NCHAR(13); 
	SET @li_error_severity = 16;
	SET @li_error_state = 1;
	SET @ls_single_quote = N'''';
	END;

	-- Declare temp tables
	BEGIN
	DROP TABLE IF EXISTS #object_class_column;

	CREATE TABLE #object_class_column
	(
		column_name SYSNAME NOT NULL PRIMARY KEY
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

	-- Get object class schema, table, source, and source_alias from [config].[object_class]
	BEGIN
	SELECT 
		@ls_object_class_table_schema_name = [table_schema_name]
	,	@ls_object_class_table_name = [table_name]
	,	@ls_object_class_source = [object_class_source]
	,	@ls_object_class_source_alias = [object_class_source_alias]
	FROM [config].[object_class]
	WHERE object_class_id = @ai_object_class_id
	;
	END;

	-- Get object's current values
	SET @ls_object_class_source = REPLACE(@ls_object_class_source, N'{alias}', @ls_object_class_source_alias);
	SET @ls_object_class_current_values_table_name = N'#object_class_current_values';

	SET @ls_sql = 
	CONCAT 
	(
		N'SELECT ', @ls_object_class_source_alias, N'.*
		INTO ', @ls_object_class_current_values_table_name, N'
		FROM ', @ls_object_class_source, N';

		EXECUTE [config].[p_sync_object_class]
			@as_object_class_current_values_table_name = ', @ls_single_quote, @ls_object_class_current_values_table_name, @ls_single_quote, N'
		,	@as_object_class_id = ', @ai_object_class_id, N'
		,	@ai_instance_id = ', @ai_instance_id, N'
		,	@ai_database_id = ', @ai_database_id, N'
		;'
	);

	IF @ai_debug_level > 0
		PRINT CONCAT(N'Executing the following in dynamic SQL: ', @ls_newline, @ls_sql);

	EXEC(@ls_sql);
	
	RETURN 0;
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

--DECLARE @lb_object_class_exists BIT;
--DECLARE @lb_is_subobject_class BIT;
--DECLARE @li_object_class_id [config].[ID];

--EXEC [config].[p_refresh_object_class] 
--	@as_object_class_name = 'tablet'
--;