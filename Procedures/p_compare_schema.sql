DROP PROCEDURE IF EXISTS [schema].[p_compare_schema];
GO

CREATE PROCEDURE [schema].[p_compare_schema]
(
	@as_database_name_left  [config].[name]
,	@as_schema_name_left    [config].[name]

,	@as_database_name_right [config].[name]
,	@as_schema_name_right   [config].[name]
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