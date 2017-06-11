DROP PROCEDURE IF EXISTS [config].[p_initialize_next_id];
GO

CREATE PROCEDURE [config].[p_initialize_next_id]
(
	@as_schema_name SYSNAME = NULL
,	@as_table_name SYSNAME = NULL
)
AS
BEGIN
	DECLARE @ls_error_msg NVARCHAR(MAX);
	DECLARE @li_table_object_id INT;

	BEGIN TRY
		IF @as_schema_name IS NOT NULL AND @as_table_name IS NOT NULL
		BEGIN
			SET @li_table_object_id = 
			(
				SELECT [object_id] 
				FROM sys.tables 
				WHERE [schema_id] = SCHEMA_ID(@as_schema_name)
					  AND 
					  [name] = @as_table_name
			);

			IF @li_table_object_id IS NULL
			BEGIN
				SET @ls_error_msg = N'Invalid schema/table combination';
				RAISERROR(@ls_error_msg, 16, 1);
			END;

			UPDATE [config].[next_id] 
			SET [next_id] = 1 
			WHERE [system_object_id] = @li_table_object_id
			;

		END;

		ELSE IF @as_schema_name IS NULL AND @as_table_name IS NULL
		BEGIN
			TRUNCATE TABLE [config].[next_id]; 
			
			INSERT INTO [config].[next_id]
			(
				[system_object_id]
			,	[next_id]
			)
			SELECT 
				[object_id]
			,	1
			FROM sys.tables 
		END;

		ELSE 
		BEGIN
			SET @ls_error_msg = '@as_schema_name and @as_table_name must both be NULL or not NULL';
			RAISERROR(@ls_error_msg, 16, 1);
		END;

		
	END TRY
	BEGIN CATCH
		SET @ls_error_msg = ERROR_MESSAGE();
		RAISERROR(@ls_error_msg, 16, 1);
	END CATCH
	
END