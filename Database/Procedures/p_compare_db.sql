DROP PROCEDURE IF EXISTS [db].[p_compare_db];
GO

CREATE PROCEDURE [db].[p_compare_db]
(
	@as_database_name_left  [config].[name]

,	@as_database_name_right [config].[name]
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