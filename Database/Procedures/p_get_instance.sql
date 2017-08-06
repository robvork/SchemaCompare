DROP PROCEDURE IF EXISTS [config].[p_get_instance];
GO

CREATE PROCEDURE [config].[p_get_instance]
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

	SELECT 
		[instance_id] 
	,	[instance_name] 
	FROM
		[config].[instance] 
	
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

--EXEC [config].[p_get_instance] 
--	@as_object_class_name = 'tablet'
--;