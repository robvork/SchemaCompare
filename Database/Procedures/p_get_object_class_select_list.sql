DROP PROCEDURE IF EXISTS [config].[p_get_object_class_select_list];
GO

CREATE PROCEDURE [config].[p_get_object_class_select_list]
(
	@as_object_class_name [config].[NAME] = NULL
,	@ai_object_class_id [config].[NAME] = NULL
,	@as_select_list NVARCHAR(MAX) OUTPUT
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
	DECLARE @ls_single_quote NCHAR(1);
	DECLARE @ls_column_name SYSNAME;
	DECLARE @ls_column_source SYSNAME;
	DECLARE @ls_select_list NVARCHAR(MAX);

	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  

	SET @ls_newline = NCHAR(13); 
	SET @ls_single_quote = N'''';

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

	DECLARE metadata_key_cursor CURSOR LOCAL FAST_FORWARD FOR 
	(
		SELECT [metadata_key_column_name] 
		,	   [metadata_key_column_source] 
		FROM 
		(
			VALUES 
			('instance_id', '{instance_id}')
		,	('database_id', '{database_id}')
		) AS standard_metadata_keys([metadata_key_column_name], [metadata_key_column_source])

		UNION ALL 

		SELECT [metadata_key_column_name] 
		,	   [metadata_key_column_source] 
		FROM [config].[object_class_metadata_key] 
		WHERE [object_class_id] = @ai_object_class_id
			  AND [metadata_key_column_name] NOT IN (N'instance_id', N'database_id')
	);

	DECLARE object_key_cursor CURSOR LOCAL FAST_FORWARD FOR
	(
		SELECT [object_key_column_name]
		,	   [object_key_column_source]
		FROM [config].[object_class_object_key]
		WHERE [object_class_id] = @ai_object_class_id
			  AND 
			  [object_key_column_name] NOT IN 
			  (
					SELECT [metadata_key_column_name] 
					FROM 
					(
						VALUES 
						('instance_id')
					,	('database_id')
					) AS standard_metadata_keys([metadata_key_column_name])

					UNION ALL 

					SELECT [metadata_key_column_name] 
					FROM [config].[object_class_metadata_key]
					WHERE [object_class_id] = @ai_object_class_id
			  )
	);
	

	DECLARE nonkey_properties_cursor CURSOR LOCAL FAST_FORWARD FOR 
	(
		SELECT QUOTENAME([object_class_property_name])
		,	   CONCAT(N'{alias}.', QUOTENAME([object_class_property_name]))
		FROM [config].[object_class_property]
		WHERE [object_class_id] = @ai_object_class_id
			  AND 
			  [object_class_property_is_metadata_key] = 0
			  AND 
			  [object_class_property_is_object_key] = 0
	);  

	SET @ls_select_list = CAST(N'' AS NVARCHAR(MAX));

	OPEN metadata_key_cursor;
	FETCH NEXT FROM metadata_key_cursor 
	INTO @ls_column_name, @ls_column_source; 

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		SET @ls_select_list = 
		CONCAT
		(
			@ls_select_list, @ls_newline
		,	N',', @ls_column_source, N' AS ', @ls_column_name
		);  

		FETCH NEXT FROM metadata_key_cursor 
		INTO @ls_column_name, @ls_column_source; 
	END;

	-- Extract the substring following the leading ','
	SET @ls_select_list = 
	CAST(SUBSTRING
	(
		@ls_select_list
	,	CHARINDEX(N',', @ls_select_list) + 1
	,	LEN(@ls_select_list)
	) AS NVARCHAR(MAX));

	OPEN object_key_cursor;
	FETCH NEXT FROM object_key_cursor 
	INTO @ls_column_name, @ls_column_source; 

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		SET @ls_select_list = 
		CONCAT
		(
			@ls_select_list, @ls_newline
		,	N',', @ls_column_source, N' AS ', @ls_column_name
		);
		
		FETCH NEXT FROM object_key_cursor 
		INTO @ls_column_name, @ls_column_source; 
	END;
	
	OPEN nonkey_properties_cursor;
	FETCH NEXT FROM nonkey_properties_cursor 
	INTO @ls_column_name, @ls_column_source; 

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		SET @ls_select_list = 
		CONCAT
		(
			@ls_select_list, @ls_newline
		,	N',', @ls_column_source, N' AS ', @ls_column_name
		);
		
		FETCH NEXT FROM nonkey_properties_cursor 
		INTO @ls_column_name, @ls_column_source; 
	END;

	SET @as_select_list = 
	CONCAT 
	(
		N'SELECT '
	,	@ls_select_list
	);

	CLOSE metadata_key_cursor;
	CLOSE object_key_cursor;
	CLOSE nonkey_properties_cursor;

	DEALLOCATE metadata_key_cursor;
	DEALLOCATE object_key_cursor;
	DEALLOCATE nonkey_properties_cursor;
	
	RETURN 0;
END TRY
BEGIN CATCH
	-- close any open cursors
	IF CURSOR_STATUS('local', 'metadata_key_cursor') > -1
		CLOSE metadata_key_cursor;
	IF CURSOR_STATUS('local', 'object_key_cursor') > -1
		CLOSE object_key_cursor;
	IF CURSOR_STATUS('local', 'nonkey_properties_cursor') > -1
		CLOSE nonkey_properties_cursor;

	-- deallocate any closed but existing cursors
	IF CURSOR_STATUS('local', 'metadata_key_cursor') > -3
		DEALLOCATE metadata_key_cursor;
	IF CURSOR_STATUS('local', 'object_key_cursor') > -3
		DEALLOCATE object_key_cursor;
	IF CURSOR_STATUS('local', 'nonkey_properties_cursor') > -3
		DEALLOCATE nonkey_properties_cursor;

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

--DECLARE @ls_select_list NVARCHAR(MAX);

--EXEC [config].[p_get_object_class_select_list]
--	@as_object_class_name = N'view_column'
--,	@as_select_list = @ls_select_list OUTPUT
--,	@ai_debug_level = 0
--;

--SET @ls_select_list = REPLACE(@ls_select_list, '{instance_id}', 1);
--SET @ls_select_list = REPLACE(@ls_select_list, '{database_id}', 2);
--SET @ls_select_list = REPLACE(@ls_select_list, '{db}', N'WideWorldImporters');
--SET @ls_select_list = REPLACE(@ls_select_list, '{alias}', N'T');

--DECLARE @ls_object_class SYSNAME = N'view_column';

--DECLARE @ls_source NVARCHAR(MAX) = 
--(
--	SELECT [object_class_source]
--	FROM [config].[object_class]
--	WHERE [object_class_name] = @ls_object_class
--);
--SET @ls_source = REPLACE(@ls_source, N'{db}', N'WideWorldImporters');
--SET @ls_source = REPLACE(@ls_source, N'{alias}', N'T');

--DECLARE @ls_sql NVARCHAR(MAX);

--SET @ls_sql = 
--CONCAT 
--(
--	@ls_select_list
--,	N' FROM '
--,	@ls_source
--);

--SELECT @ls_sql;
--EXEC(@ls_sql);
--DECLARE @ls_sql NVARCHAR(MAX);
--SELECT * FROM [config].[object_class]
