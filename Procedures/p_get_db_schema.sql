DROP PROCEDURE IF EXISTS [schema].[p_get_schema];
GO

CREATE PROCEDURE [schema].[p_get_schema]
(
	@as_database_name [config].[name]
,	@as_schema_name [config].[name]
,	@ab_db_exists BIT OUTPUT
,	@ai_db_id [config].[ID] OUTPUT
,	@ab_schema_exists BIT OUTPUT
,	@ai_schema_id [config].[ID] OUTPUT
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