DROP PROCEDURE IF EXISTS [config].[p_get_subobjects];
GO

CREATE PROCEDURE [config].[p_get_subobjects]
(
	@ai_object_class_id [config].[ID]
,	@ab_has_subobjects BIT OUTPUT
,	@as_subobject_table_name [config].[NAME]
)
AS
BEGIN
	BEGIN TRY
		RETURN 0;
	END TRY
	BEGIN CATCH
		RETURN 1;
	END CATCH
END;