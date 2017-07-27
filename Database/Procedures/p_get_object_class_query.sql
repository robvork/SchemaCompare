DROP PROCEDURE IF EXISTS [config].[p_get_object_class_query];
GO

CREATE PROCEDURE [config].[p_get_object_class_query]
(
	@as_object_class_name [config].[NAME] = NULL
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
	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  

	SET @ls_newline = NCHAR(13); 

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
			[object_class_name]
			, [object_class_id]
			, CONCAT
			( 
				N''SELECT '', [object_class_source_alias], N''.*
				FROM '', REPLACE(REPLACE([object_class_source], N''{alias}'', [object_class_source_alias]), ''{db}'',''', @as_database_name, ''')
			) AS [object_class_query]
			FROM [config].[object_class] 
		'
	,	@ls_name_filter
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


--EXEC [config].[p_get_object_class_query] 
--	@as_object_class_name = 'procedure_param' 
--,	@as_database_name = 'wideworldimporters'
--,	@ai_debug_level = 1
--;