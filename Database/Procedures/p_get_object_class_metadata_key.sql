DROP PROCEDURE IF EXISTS [config].[p_get_object_class_metadata_key];
GO

CREATE PROCEDURE [config].[p_get_object_class_metadata_key]
(
	@as_object_class_name [config].[NAME] = NULL
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
			'WHERE MK.[object_class_id] = '''
		,	(
				SELECT [object_class_id] 
				FROM [config].[object_class] 
				WHERE [object_class_name] = @as_object_class_name
			)
		,   ''''
		); 
	END;

	SET @ls_sql = 
	CONCAT 
	(
		N'SELECT 
			MK.[object_class_id]
		,	OC.[object_class_name] 
		,	MK.[metadata_key_column_id]
		,	MK.[metadata_key_column_name] 
		,	MK.[metadata_key_column_type]
		,	MK.[metadata_key_column_source]
		  FROM 
			[config].[object_class_metadata_key] AS MK
				INNER JOIN [config].[object_class] AS OC
					ON MK.[object_class_id] = OC.[object_class_id]  
		'
	,	@ls_name_filter 
	); 

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

--EXEC [config].[p_get_object_class_metadata_key] 
--	@as_object_class_name = NULL 
--;