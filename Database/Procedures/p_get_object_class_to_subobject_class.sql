DROP PROCEDURE IF EXISTS [config].[p_get_object_class_to_subobject_class];
GO

CREATE PROCEDURE [config].[p_get_object_class_to_subobject_class]
(
	@as_object_class_name [config].[NAME] = NULL
,	@as_subobject_class_name [config].[NAME] = NULL
)
AS
BEGIN
BEGIN TRY
	SET NOCOUNT ON;
	DECLARE @ls_sql NVARCHAR(MAX); 
	DECLARE @ls_class_filter NVARCHAR(MAX); 
	DECLARE @ls_error_msg NVARCHAR(MAX);
	DECLARE @ls_newline NCHAR(1); 
	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  

	DECLARE @li_object_class_id INT;
	DECLARE @lb_has_valid_object_class BIT;

	DECLARE @li_subobject_class_id INT;
	DECLARE @lb_has_valid_subobject_class BIT;

	SET @ls_newline = NCHAR(13); 
	SET @li_object_class_id = NULL;
	SET @li_subobject_class_id = NULL;
	SET @lb_has_valid_object_class = 0;
	SET @lb_has_valid_subobject_class = 0;

	IF @as_object_class_name IS NOT NULL 
	BEGIN
		SET @li_object_class_id = 
		(
			SELECT [object_class_id]
			FROM [config].[object_class] 
			WHERE [object_class_name] = @as_object_class_name
		);

		IF @li_object_class_id IS NULL
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
		ELSE 
			SET @lb_has_valid_object_class = 1;
	END;

	IF @as_subobject_class_name IS NOT NULL 
	BEGIN
		SET @li_subobject_class_id = 
		(
			SELECT [object_class_id] 
			FROM [config].[object_class] 
			WHERE [object_class_name] = @as_subobject_class_name
		);

		IF @li_subobject_class_id IS NULL
		BEGIN
			SET @ls_error_msg = 
			CONCAT
			(
				N'Invalid subobject class name ''', 
				@as_subobject_class_name, 
				N''''
			); 
			SET @li_error_severity = 16; 
			SET @li_error_state = 1; 

			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state); 
		END; 
		ELSE 
			SET @lb_has_valid_subobject_class = 1;
	END;

	IF @lb_has_valid_object_class = 1 AND @lb_has_valid_subobject_class = 1
	BEGIN
		SET @ls_class_filter = 
		CONCAT(
			N'WHERE OC1.object_class_id = '
		,	@li_object_class_id
		,	@ls_newline
		,	N'  AND OC2.subobject_class_id = '
		,	@li_subobject_class_id
		,	N';'
			 );
	END;
	ELSE IF @lb_has_valid_object_class = 1
	BEGIN
		SET @ls_class_filter = 
		CONCAT 
		(
			N'WHERE OC1.object_class_id = '
		,	@li_object_class_id
		,	N';'
		); 
	END;
	ELSE IF @lb_has_valid_subobject_class = 1
	BEGIN
		SET @ls_class_filter = 
		CONCAT 
		(
			N'WHERE OC2.object_class_id = '
		,	@li_subobject_class_id
		,	N';'
		); 
	END;
	ELSE 
	BEGIN
		SET @ls_class_filter = NULL;
	END; 

	SET @ls_sql = 
	CONCAT 
	(
		N'SELECT 
			OC1.[object_class_id]
		,	OC1.[object_class_name] 
		,	OC2.[object_class_id] AS [subobject_class_id]
		,	OC2.[object_class_name] AS [subobject_class_name]
		  FROM 
			[config].[object_to_subobject]  AS O2S
		  INNER JOIN [config].[object_class] AS OC1
			ON O2S.object_class_id = OC1.object_class_id
		  INNER JOIN [config].[object_class] AS OC2
			ON O2S.subobject_class_id = OC2.object_class_id
		'
	,	@ls_class_filter 
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

DECLARE @ls_object_class_name SYSNAME = NULL;
DECLARE @ls_subobject_class_name SYSNAME = NULL;

EXEC [config].[p_get_object_class_to_subobject_class] 
	@as_object_class_name = @ls_object_class_name
,	@as_subobject_class_name = @ls_subobject_class_name
;
