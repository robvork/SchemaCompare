DROP PROCEDURE IF EXISTS [config].[p_initialize_system_type];
GO

CREATE PROCEDURE [config].[p_initialize_system_type]
(
	@ai_debug_level INT = 0
)
AS
BEGIN
	BEGIN TRY
		DECLARE @ls_error_msg NVARCHAR(MAX);
		EXEC [config].[p_initialize_next_id]
			@as_schema_name = 'config'
		,	@as_table_name = 'system_type'
		;	

		IF @ai_debug_level > 1
		BEGIN
			SELECT '[config].[system_type] at the BEGINNING of procedure';
			SELECT * FROM [config].[system_type];
		END;

		IF EXISTS(SELECT * FROM [config].[system_type])
		BEGIN
			TRUNCATE TABLE [config].[system_type];

			IF @ai_debug_level > 1
			BEGIN
				SELECT '[config].[system_type] has been truncated and is now empty';
			END;
		END

		DROP TABLE IF EXISTS #system_type 

		CREATE TABLE #system_type 
		(
			[row_num] INT NOT NULL
		,	[row_id] INT NULL
		,	[system_type_name] NVARCHAR(128) NOT NULL
		,	[system_type_has_length] BIT NOT NULL
		);

		WITH system_types AS
		(
			SELECT 
				[system_type_name] 
			,	[system_type_has_length] 
			FROM 
			(
				VALUES 
				('BIT', 0)
			,	('TINYINT', 0)
			,	('SMALLINT', 0)
			,	('INT', 0)
			,	('BIGINT', 0)
			,	('NCHAR', 1)
			,	('NVARCHAR', 1)
			,	('CHAR', 1)
			,	('VARCHAR', 1)
			,	('SYSNAME', 0)
			,	('DATETIME', 0)
			) AS system_type_values([system_type_name], [system_type_has_length])
		)
		INSERT INTO #system_type
		(
			[row_num]
		,	[system_type_name]
		,	[system_type_has_length]
		)
		SELECT 
			ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		,	[system_type_name]
		,	[system_type_has_length]
		FROM system_types
		;

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#system_type BEFORE assigning IDs';
			SELECT * FROM #system_type;
		END;

		EXEC [config].[p_get_next_id] 
			@as_schema_name = 'config'
		,	@as_table_name = 'system_type' 
		,	@as_work_table_name = '#system_type'
		; 

		IF @ai_debug_level > 1
		BEGIN
			SELECT '#system_type AFTER assigning IDs';
			SELECT * FROM #system_type;
		END;

		--IF @ai_debug_level > 1
		--BEGIN
		--	SELECT '[config].[system_type] at the END of procedure';
		--	SELECT * FROM [config].[system_type];
		--END;

	END TRY
	BEGIN CATCH
		SET @ls_error_msg = ERROR_MESSAGE();
		RAISERROR(@ls_error_msg, 16, 1);
	END CATCH;
END 