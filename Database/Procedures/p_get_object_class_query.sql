DROP PROCEDURE IF EXISTS [config].[p_get_object_class_query];
GO

CREATE PROCEDURE [config].[p_get_object_class_query]
(
	@as_object_class_name [config].[NAME] = NULL
,	@as_instance_name SYSNAME
,	@as_database_name SYSNAME
,	@ai_debug_level INT = 0
)
AS
BEGIN
BEGIN TRY
	SET NOCOUNT ON;
	DECLARE @ls_sql NVARCHAR(MAX); 
	DECLARE @ls_name_filter NVARCHAR(1000); 
	DECLARE @ls_error_msg NVARCHAR(MAX);
	DECLARE @ls_newline NCHAR(1); 
	DECLARE @ls_object_class_query NVARCHAR(MAX);
	DECLARE @ls_select_list NVARCHAR(MAX);
	DECLARE @ls_object_class_source NVARCHAR(MAX);
	DECLARE @ls_object_class_source_alias SYSNAME;

	DECLARE @li_object_class_id SYSNAME;
	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  
	DECLARE @li_instance_id INT;
	DECLARE @li_database_id INT;

	SET @ls_newline = NCHAR(13); 

	DROP TABLE IF EXISTS #object_class_scope;

	CREATE TABLE #object_class_scope
	(
		[object_class_id] INT NOT NULL PRIMARY KEY
	,	[object_class_name] SYSNAME NOT NULL
	,	[object_class_query] NVARCHAR(MAX) NULL
	,	[object_class_source] NVARCHAR(MAX) NOT NULL
	,	[object_class_source_alias] SYSNAME NOT NULL
	);

	IF @as_object_class_name IS NOT NULL AND @as_object_class_name <> N''
	BEGIN
		IF NOT EXISTS 
		(
			SELECT * 
			FROM [config].[object_class] 
			WHERE [object_class_name] = @as_object_class_name
		)
		BEGIN
			SET @ls_error_msg = 
			CONCAT
			(
				N'Invalid object class name ''', 
				@as_object_class_name, 
				N''''
			); 
			SET @li_error_severity = 16; 
			SET @li_error_state = 1; 

			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state); 
		END; 

		SET @ls_name_filter = 
		CONCAT
		(
			'WHERE [object_class_name] = '''
		,	@as_object_class_name
		,   ''''
		); 
	END;

	IF NOT EXISTS 
	(
		SELECT * 
		FROM [config].[instance]
		WHERE [instance_name] = @as_instance_name
	)
	BEGIN
		SET @ls_error_msg = FORMATMESSAGE('''%s'' is not a recognized instance name', @as_instance_name);
		RAISERROR(@ls_error_msg, 16, 1);
	END;
	ELSE 
		SET @li_instance_id = 
		(
			SELECT [instance_id] 
			FROM [config].[instance] 
			WHERE [instance_name] = @as_instance_name
		); 

	IF NOT EXISTS 
	(
		SELECT * 
		FROM [config].[database]
		WHERE [database_name] = @as_database_name
	)
	BEGIN
		SET @ls_error_msg = FORMATMESSAGE('''%s'' is not a recognized database name', @as_database_name);
		RAISERROR(@ls_error_msg, 16, 1);
	END;
	ELSE 
		SET @li_database_id = 
		(
			SELECT [database_id] 
			FROM [config].[database] 
			WHERE [database_name] = @as_database_name
		); 

	-- if @as_object_class_name was NULL, all object classes are in scope
	-- otherwise we validated that @as_object_class_name was valid, so only that object class is in scope
	SET @ls_sql = 
	CONCAT 
	(
		N'INSERT INTO #object_class_scope
		(
			[object_class_id]
		,	[object_class_name]
		,	[object_class_source]
		,	[object_class_source_alias]
		)
		SELECT 
			[object_class_id]
		,	[object_class_name]
		,	[object_class_source]
		,	[object_class_source_alias]
		FROM 
			[config].[object_class]
		'
	,	@ls_name_filter
	);

	IF @ai_debug_level > 0
		PRINT CONCAT('Executing in dynamic SQL: ', @ls_newline, @ls_sql);

	EXEC(@ls_sql); 

	IF @ai_debug_level > 1
	BEGIN
		SELECT '#object_class_scope';
		SELECT * FROM #object_class_scope;
	END;

	DECLARE object_class_cursor CURSOR LOCAL FAST_FORWARD
	FOR 
	(
		SELECT [object_class_id]
		,	   [object_class_source]
		,	   [object_class_source_alias]
		FROM #object_class_scope
	);

	OPEN object_class_cursor; 
	FETCH NEXT FROM object_class_cursor 
	INTO @li_object_class_id
	,	 @ls_object_class_source
	,	 @ls_object_class_source_alias
	;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE [config].[p_get_object_class_select_list]
			@ai_object_class_id = @li_object_class_id 
		,	@as_select_list = @ls_select_list OUTPUT 
		;

		SET @ls_select_list = REPLACE(@ls_select_list, N'{instance_id}', @li_instance_id);
		SET @ls_select_list = REPLACE(@ls_select_list, N'{database_id}', @li_database_id);
		SET @ls_select_list = REPLACE(@ls_select_list, N'{alias}', @ls_object_class_source_alias);

		SET @ls_object_class_source = REPLACE(@ls_object_class_source, N'{alias}', @ls_object_class_source_alias);
		SET @ls_object_class_source = REPLACE(@ls_object_class_source, N'{db}', @as_database_name);

		SET @ls_object_class_query = 
		CONCAT 
		(
			@ls_select_list, @ls_newline 
		,	N'FROM ', @ls_object_class_source
		);

		UPDATE #object_class_scope 
		SET [object_class_query] = @ls_object_class_query
		WHERE [object_class_id] = @li_object_class_id
		;

		FETCH NEXT FROM object_class_cursor 
		INTO @li_object_class_id
		,	 @ls_object_class_source
		,	 @ls_object_class_source_alias
		;
	END;

	SELECT [object_class_name] 
	,	   [object_class_id] 
	,	   [object_class_query] 
	FROM #object_class_scope
	;

	CLOSE object_class_cursor;
	DEALLOCATE object_class_cursor;
	
	RETURN 0;
END TRY
BEGIN CATCH
	IF CURSOR_STATUS('local', 'object_class_cursor') > -1
		CLOSE object_class_cursor;

	IF CURSOR_STATUS('local', 'object_class_cursor') > -3
		DEALLOCATE object_class_cursor;

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

EXEC [config].[p_get_object_class_query]
	@as_object_class_name = NULL
,	@as_instance_name = N'ASPIRING\SQL16'
,	@as_database_name = N'WideWorldImporters'
,	@ai_debug_level = 2
;


--EXEC [config].[p_get_object_class_query] 
--	@as_object_class_name = 'procedure_param' 
--,	@as_database_name = 'wideworldimporters'
--,	@ai_debug_level = 1
--;

--SELECT * 
--FROM [config].[object_class_property] AS OCP
--	INNER JOIN [config].[object_class] AS OC
--		ON OCP.[object_class_id] = OC.[object_class_id]
--WHERE [object_class_name] = N'table'