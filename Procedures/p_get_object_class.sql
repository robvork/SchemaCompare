DROP PROCEDURE IF EXISTS [config].[p_get_object_class];
GO

CREATE PROCEDURE [config].[p_get_object_class]
(
	@as_object_class_name [config].[NAME]
,	@ab_object_class_exists BIT OUTPUT
,	@ab_is_subobject_class BIT OUTPUT
,	@ai_object_class_id [config].[ID] OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		RETURN 0;
	END TRY
	BEGIN CATCH
		RETURN 1;
	END CATCH
END;