DROP PROCEDURE IF EXISTS [config].[p_get_standard_metadata_key];
GO

CREATE PROCEDURE [config].[p_get_standard_metadata_key]
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
	
	SELECT 
		[standard_metadata_key_id] 
	,	[standard_metadata_key_name] 
	,	[standard_metadata_key_type] 
	,	[standard_metadata_key_precedence]
	FROM 
		[config].[standard_metadata_key]
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

--EXEC [config].[p_get_standard_metadata_key]
--	@as_object_class_name = NULL
--,	@as_instance_name = N'ASPIRING\SQL16'
--,	@as_database_name = N'WideWorldImporters'
--,	@ai_debug_level = 1
--;


--EXEC [config].[p_get_standard_metadata_key] 
--	@as_object_class_name = 'procedure_param' 
--,	@as_database_name = 'wideworldimporters'
--,	@ai_debug_level = 1
--;

--SELECT * 
--FROM [config].[object_class_property] AS OCP
--	INNER JOIN [config].[object_class] AS OC
--		ON OCP.[object_class_id] = OC.[object_class_id]
--WHERE [object_class_name] = N'table'