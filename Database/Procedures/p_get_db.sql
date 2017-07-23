DROP PROCEDURE IF EXISTS [config].[p_get_db];
GO

CREATE PROCEDURE [config].[p_get_db]
(
	@as_database_name [config].[NAME]
,	@ab_db_exists BIT OUTPUT
,	@ai_db_id [config].[ID] OUTPUT
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