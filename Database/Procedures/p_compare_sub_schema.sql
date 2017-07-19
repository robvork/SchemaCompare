DROP PROCEDURE IF EXISTS [sub_schema].[p_compare_sub_schema];
GO

CREATE PROCEDURE [sub_schema].[p_compare_sub_schema]
(
	@as_database_name_left			   [config].[name]
,	@as_schema_name_left			   [config].[name]

,	@as_database_name_right			   [config].[name]
,	@as_schema_name_right              [config].[name]

,	@as_sub_schema_object_class_name   [config].[name]
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		RETURN 0;
	END TRY
	BEGIN CATCH
		RETURN 1;
	END CATCH; 
END;