DROP PROCEDURE IF EXISTS [config].[p_get_object_to_subobject_name_query];
GO

CREATE PROCEDURE [config].[p_get_object_to_subobject_name_query]
(
	@as_object_class_name [config].[NAME] = NULL
,	@ai_object_class_id INT = NULL
,	@as_subobject_class_name [config].[NAME] = NULL
,	@ai_subobject_class_id INT = NULL
,	@as_database_name SYSNAME
,	@ai_debug_level INT = 0
)
AS
BEGIN
BEGIN TRY
	SET NOCOUNT ON;
	DECLARE @ls_sql NVARCHAR(MAX); 
	DECLARE @ls_class_filter NVARCHAR(1000); 
	DECLARE @ls_error_msg NVARCHAR(MAX);
	DECLARE @ls_newline NCHAR(1); 
	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  

	DECLARE @lb_object_class_specified BIT;
	DECLARE @lb_subobject_class_specified BIT;

	SET @lb_object_class_specified = 0;
	SET @lb_subobject_class_specified = 0;
	SET @ls_newline = NCHAR(13); 
	SET @li_error_severity = 16;
	SET @li_error_state = 1;

	-- Validate/Set object class
	BEGIN
		IF @as_object_class_name IS NULL AND @ai_object_class_id IS NULL
			SET @lb_object_class_specified = 0;
		
		ELSE IF @as_object_class_name IS NOT NULL AND @ai_object_class_id IS NOT NULL
		BEGIN
			SET @lb_object_class_specified = 0;
			SET @ls_error_msg = N'At most one of @as_object_class_name or @ai_object_class_id can be non-NULL';
			RAISERROR(@ls_error_msg, @ls_error_severity, @ls_error_state);
		END; 

		ELSE IF @as_object_class_name IS NOT NULL 
		BEGIN
			SET @ai_object_class_id = 
			(
				SELECT [object_class_id] 
				FROM [config].[object_class] 
				WHERE [object_class_name] = @as_object_class_name
			);

			IF @ai_object_class_id = NULL 
			BEGIN
				SET @lb_object_class_specified = 0;
				SET @ls_error_msg = FORMATMESSAGE(N'%s is not a valid object class name.', QUOTENAME(@as_object_class_name, N''''));
				RAISERROR(@ls_error_msg, @ls_error_severity, @ls_error_state);
			END;
			ELSE 
				SET @lb_object_class_specified = 1;
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
				SET @lb_object_class_specified = 0;
				SET @ls_error_msg = FORMATMESSAGE(N'%i is not a valid object class id.', @ai_object_class_id);
				RAISERROR(@ls_error_msg, @ls_error_severity, @ls_error_state);
			END;
			ELSE 
				SET @lb_object_class_specified = 1; 
		END;
	END;

	-- Validate/Set subobject class
	BEGIN
		IF @as_subobject_class_name IS NULL AND @ai_subobject_class_id IS NULL
			SET @lb_subobject_class_specified = 0;
		
		ELSE IF @as_subobject_class_name IS NOT NULL AND @ai_subobject_class_id IS NOT NULL
		BEGIN
			SET @lb_subobject_class_specified = 0;
			SET @ls_error_msg = N'At most one of @as_subobject_class_name or @ai_subobject_class_id can be non-NULL';
			RAISERROR(@ls_error_msg, @ls_error_severity, @ls_error_state);
		END; 

		ELSE IF @as_subobject_class_name IS NOT NULL 
		BEGIN
			SET @ai_subobject_class_id = 
			(
				SELECT [object_class_id] 
				FROM [config].[object_class] 
				WHERE [object_class_name] = @as_subobject_class_name
			);

			IF @ai_subobject_class_id = NULL 
			BEGIN
				SET @lb_subobject_class_specified = 0;
				SET @ls_error_msg = FORMATMESSAGE(N'%s is not a valid object class name.', QUOTENAME(@as_subobject_class_name, N''''));
				RAISERROR(@ls_error_msg, @ls_error_severity, @ls_error_state);
			END;
			ELSE 
				SET @lb_subobject_class_specified = 1;
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
				SET @lb_subobject_class_specified = 0;
				SET @ls_error_msg = FORMATMESSAGE(N'%i is not a valid object class id.', @ai_subobject_class_id);
				RAISERROR(@ls_error_msg, @ls_error_severity, @ls_error_state);
			END;
			ELSE 
				SET @lb_subobject_class_specified = 1; 
		END;
	END;

	IF @lb_object_class_specified = 1 AND @lb_subobject_class_specified = 1
	BEGIN
		SET @ls_class_filter = 
		CONCAT 
		(
			N'WHERE [object_class_id] = '
		,	@ai_object_class_id
		,	N'AND [subobject_class_id] = '
		,	@ai_subobject_class_id
		);
	END;
	ELSE IF @lb_object_class_specified = 1
	BEGIN
		SET @ls_class_filter = 
		CONCAT 
		(
			N'WHERE [object_class_id] = '
		,	@ai_object_class_id
		); 
	END;
	ELSE IF @lb_subobject_class_specified = 1
	BEGIN
		SET @ls_class_filter = 
		CONCAT 
		(
			N'WHERE [subobject_class_id] = '
		,	@ai_subobject_class_id
		); 
	END;
	ELSE IF @lb_object_class_specified = 0 AND @lb_subobject_class_specified = 0
		SET @ls_class_filter = N'';

	/* 
	 The query below is a little nasty looking, but it's quite simple. We're just querying the object class name and id
	 and constructing a query on @as_database_name's metadata. [object_class_source] provides a FROM source that can be used
	 on any SQL Server database. within [object_class_source] is a special replace token '{alias}' which must be replaced by
	 a legal SQL Server alias. [object_class_source_alias] provides one such possibility.
	 The query performs a SELECT * FROM @as_database_name.<source_with_alias_replaced>, where <source_with_alias_replaced> is the 
	 metadata source with {alias} replaced by the value in [object_class_source_alias].
	*/
	SET @ls_sql = 
	CONCAT 
	(
		N'
			SELECT 
			  OC1.[object_class_name]
			, OC1.[object_class_id]
			, OC2.[object_class_name]
			, OC2.[object_class_id]
			, CONCAT
			( 
				N''SELECT '', [object_class_source_alias], N''.*
				FROM '', REPLACE(REPLACE([object_class_source], N''{alias}'', [object_class_source_alias]), ''{db}'',''', @as_database_name, ''')
			) AS [object_class_query]
			FROM [config].[object_class] 
		'
	,	@ls_class_filter
	,	N';'
	); 

	IF @ai_debug_level > 0
		PRINT CONCAT('Executing in dynamic SQL: ', @ls_newline, @ls_sql);

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


--EXEC [config].[p_get_object_to_subobject_name_query] 
--	@as_object_class_name = 'procedure_param' 
--,	@as_database_name = 'wideworldimporters'
--,	@ai_debug_level = 1
--;

--SELECT * 
--FROM [config].[object_class_property] AS OCP
--	INNER JOIN [config].[object_class] AS OC
--		ON OCP.[object_class_id] = OC.[object_class_id]
--WHERE [object_class_name] = N'table'