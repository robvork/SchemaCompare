DROP PROCEDURE IF EXISTS [config].[p_get_next_id];
GO

CREATE PROCEDURE [config].[p_get_next_id]
(
	-- This must be a temp table with a column object_id of type INT
	@as_schema_name [config].[NAME]
,	@as_table_name [config].[NAME]
,	@ai_num_ids_needed INT = 1
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @ls_sql NVARCHAR(MAX);
		DECLARE @ls_error_msg NVARCHAR(MAX);

		DECLARE @li_system_id [config].[ID];
		DECLARE @li_min_new_id [config].[ID];
		DECLARE @li_max_new_id [config].[ID];
	
		SET @li_system_id = 
		(
			SELECT [object_id] 
			FROM sys.tables 
			WHERE [schema_id] = SCHEMA_ID(@as_schema_name) 
				  AND 
				  [name] = @as_table_name
		);

		IF @li_system_id IS NULL
		BEGIN
			SET @ls_error_msg = N'Invalid schema/table name combination';
			RAISERROR(@ls_error_msg, 16, 1);	
		END;

		SET @li_min_new_id = 
		(
			SELECT [next_id]
			FROM [config].[next_id] 
			WHERE [system_object_id] = @li_system_id
		);

		SET @li_max_new_id = @li_min_new_id + @ai_num_ids_needed - 1;

		UPDATE [config].[next_id]
		SET [next_id] = @li_max_new_id + 1
		WHERE [system_object_id] = @li_system_id
		;

		SELECT n 
		FROM [config].[get_nums]
		(
			@li_min_new_id
		,	@li_max_new_id
		)
		;

	END TRY
	BEGIN CATCH
		SET @ls_error_msg = ERROR_MESSAGE();
		RAISERROR(@ls_error_msg, 16, 1);
	END CATCH;
END; 