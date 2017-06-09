DROP PROCEDURE IF EXISTS [schema].[p_compare_object];
GO

CREATE PROCEDURE [schema].[p_compare_object]
(
	@as_database_name_left		[config].[name]
,	@as_schema_name_left		[config].[name]
,	@as_object_name_left		[config].[name]

,	@as_database_name_right		[config].[name]
,	@as_schema_name_right       [config].[name]
,	@as_object_name_right		[config].[name]

,	@as_object_class_name		[config].[name]
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