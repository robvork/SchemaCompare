DROP PROCEDURE IF EXISTS [config].[p_create_object_column_code];
GO

CREATE PROCEDURE [config].[p_create_object_column_code]
(
	@as_object_class_name [config].[NAME] = NULL
,	@ai_object_class_id [config].[ID] = NULL
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
				N'''.'
			); 
			SET @li_error_severity = 16; 
			SET @li_error_state = 1; 

			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state); 
		END; 

		SET @ai_object_class_id = 
		(
			SELECT [object_class_id] 
			FROM [object_class]
			WHERE [object_class_name] = @as_object_class_name
		); 
	END;

	IF @ai_object_class_id IS NOT NULL
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
				N'Invalid object class id '
			,	@ai_object_class_id
			,	N'.'
			);
			SET @li_error_severity = 16;
			SET @li_error_state = 1;
			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state); 
		END; 
	END; 

	SELECT 
	CONCAT 
	(
		CONCAT(N'[', OCP.[object_class_property_name], N']')
	,	N' '
	,   UPPER(OCP.[object_class_property_type_name])
	,	CASE 
			WHEN OCP.[object_class_property_has_length] = 1 
				THEN CONCAT(N'(', OCP.[object_class_property_length], N')')
			ELSE 
					 N''
		END
	,	N' '
	,	CASE 
			WHEN OCP.[object_class_property_is_nullable] = 1 
				THEN N'NULL'
			ELSE 
					 N'NOT NULL'
		END 
	) AS [column_sql]
	FROM [config].[object_class_property] AS OCP
	WHERE OCP.[object_class_id] = @ai_object_class_id
	;

	
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

--DECLARE @li_object_class_id [config].[ID];

--EXEC [config].[p_create_object_column_code] 
--	@as_object_class_name = 'table'
--;