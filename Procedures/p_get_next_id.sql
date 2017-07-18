DROP PROCEDURE IF EXISTS [config].[p_get_next_id];
GO

CREATE PROCEDURE [config].[p_get_next_id]
(
	@as_schema_name [config].[NAME]
,	@as_table_name [config].[NAME]
,	@as_work_table_name [config].[name]
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
	/*******************************************************************************
	Declare local variables
	*******************************************************************************/
		DECLARE @ls_sql NVARCHAR(MAX);
		DECLARE @ls_error_msg NVARCHAR(MAX);
		DECLARE @ls_params NVARCHAR(MAX);

		DECLARE @li_table_system_id [config].[ID];
		DECLARE @li_num_ids_needed INT;
		DECLARE @li_min_new_id [config].[ID];
		DECLARE @li_max_new_id [config].[ID];
		DECLARE @li_int_system_type_id INT;
		DECLARE @li_work_table_object_id INT;

		DECLARE @lb_passes_validation BIT;
	/*******************************************************************************
	Create temp tables
	*******************************************************************************/
	DROP TABLE IF EXISTS #row_num_to_id;

	CREATE TABLE #row_num_to_id
	(
		[row_num] INT NOT NULL PRIMARY KEY
	,	[row_id] INT NOT NULL UNIQUE
	)

	/*******************************************************************************
	Initialize local variables
	*******************************************************************************/
		-- Get sys.tables.row_id of the table for which we are generating the next id(s)
		SET @li_table_system_id = 
		(
			SELECT [object_id] 
			FROM sys.tables 
			WHERE [schema_id] = SCHEMA_ID(@as_schema_name) 
				  AND 
				  [name] = @as_table_name
		);

		-- Get the system_type_id of the system INT datatype
		SET @li_int_system_type_id = 
		(
			SELECT [system_type_id]
			FROM sys.types
			WHERE [name] = 'INT'
		);

		-- Get the tempdb.dbo.sys.objects.row_id of the work table (if it exists)
		SET @li_work_table_object_id = OBJECT_ID('tempdb.dbo.' + @as_work_table_name);

		-- Get the row count of the work table to determine how many ids we need to generate
		-- If the table does not exist or is empty, this value will be NULL
		SET @ls_params = N'@ai_num_ids_needed INT OUTPUT';
		SET @ls_sql = 
		CONCAT
		(
			'SET @ai_num_ids_needed = 
			 (
				SELECT COUNT(*) 
				FROM ', @as_work_table_name, N'
			 );'
		)

		EXEC sp_executesql 
			@stmt = @ls_sql 
		,	@params = @ls_params 
		,	@ai_num_ids_needed = @li_num_ids_needed OUTPUT 
		;

		PRINT CONCAT('@li_num_ids_needed:', @li_num_ids_needed);
	/*******************************************************************************
	Validate parameters
	*******************************************************************************/
		-- Validate the schema and table of the table for which we are generating ids
		IF @li_table_system_id IS NULL
		BEGIN
			SET @ls_error_msg = N'Invalid schema/table name combination';
			RAISERROR(@ls_error_msg, 16, 1);	
		END;

		-- Validate the existence of the work table @as_work_table_name in tempdb
		IF @li_work_table_object_id IS NULL
		BEGIN
			SET @ls_error_msg = N'@as_work_table_name must be an existing temp table';
			RAISERROR(@ls_error_msg, 16, 1);
		END;

		-- Validate that @as_work_table_name has a column [row_id] INT NULL
		SET @ls_params = N'@ab_passes_validation BIT OUTPUT';
		SET @ls_sql = 
		CONCAT
		(
			N'IF EXISTS 
			(
				SELECT * 
				FROM tempdb.sys.columns 
				WHERE [name] = ''row_id''
					  AND 
					  [system_type_id] = ', @li_int_system_type_id, N'
					  AND 
					  [object_id] = ', @li_work_table_object_id, N' 
					  AND
					  [is_nullable] = 1
			)
				SET @ab_passes_validation = 1;
			ELSE
				SET @ab_passes_validation = 0;
			'
		);

		EXEC sp_executesql @stmt = @ls_sql 
		,				   @params = @ls_params 
		,				   @ab_passes_validation = @lb_passes_validation OUTPUT 
		;

		IF @lb_passes_validation = 0
		BEGIN
			SET @ls_error_msg = N'@as_work_table_name must have a column [row_id] INT NULL';
			RAISERROR(@ls_error_msg, 16, 1);
		END;

		-- Validate that @as_work_table_name has a column [row_num] INT NOT NULL
		SET @ls_sql = 
		CONCAT
		(
			N'IF EXISTS 
			(
				SELECT * 
				FROM tempdb.sys.columns 
				WHERE [name] = ''row_num''
					  AND 
					  [system_type_id] = ', @li_int_system_type_id, N'
					  AND 
					  [object_id] = ', @li_work_table_object_id, N' 
					  AND
					  [is_nullable] = 0
			)
				SET @ab_passes_validation = 1;
			ELSE
				SET @ab_passes_validation = 0;
			'
		);

		EXEC sp_executesql @stmt = @ls_sql 
		,				   @params = @ls_params 
		,				   @ab_passes_validation = @lb_passes_validation OUTPUT 
		;

		IF @lb_passes_validation = 0
		BEGIN
			SET @ls_error_msg = N'@as_work_table_name must have a column [row_num] INT';
			RAISERROR(@ls_error_msg, 16, 1);
		END;

		-- Validate that all values of @as_work_table.row_id are NULL. Otherwise we'd lose whatever
		-- that column contained in this procedure.
		SET @ls_sql = 
		CONCAT
		(
			N'IF EXISTS 
			(
				SELECT * 
				FROM ', @as_work_table_name, '
				WHERE [row_id] IS NOT NULL
			)
				SET @ab_passes_validation = 0;
			ELSE
				SET @ab_passes_validation = 1;
			'
		);
		
		EXEC sp_executesql @stmt = @ls_sql 
		,				   @params = @ls_params 
		,				   @ab_passes_validation = @lb_passes_validation OUTPUT 
		;

		IF @lb_passes_validation = 0
		BEGIN
			SET @ls_error_msg = N'@as_work_table_name.row_id must be NULL for all rows';
			RAISERROR(@ls_error_msg, 16, 1);
		END;

		-- Validate that @as_work_table.row_num is unique (i.e. each value has exactly one occurrence)
		SET @ls_sql = 
		CONCAT
		(
			N'IF EXISTS 
			(
				SELECT *
				FROM ', @as_work_table_name, '
				GROUP BY [row_num]
				HAVING COUNT(*) > 1
			)
				SET @ab_passes_validation = 0;
			ELSE
				SET @ab_passes_validation = 1;
			'
		);
		
		EXEC sp_executesql @stmt = @ls_sql 
		,				   @params = @ls_params 
		,				   @ab_passes_validation = @lb_passes_validation OUTPUT 
		;

		IF @lb_passes_validation = 0
		BEGIN
			SET @ls_error_msg = N'@as_work_table_name.row_num must be unique across all rows';
			RAISERROR(@ls_error_msg, 16, 1);
		END;

		-- Validate that @as_work_table_name.row_num only takes on values between 
		-- 1 and r, where r is the row count of @as_work_table_name.
		-- This is important for the matching of row_num between the work table 
		-- and a local temp table containing the new IDs
		SET @ls_sql = 
		CONCAT
		(
			N'
			DECLARE @li_rc INT = (SELECT COUNT(*) FROM ', @as_work_table_name, N');
			IF EXISTS 
			(
				SELECT *
				FROM ', @as_work_table_name, '
				WHERE [row_num] < 1 OR [row_num] > @li_rc
			)
				SET @ab_passes_validation = 0;
			ELSE
				SET @ab_passes_validation = 1;
			'
		);
		
		EXEC sp_executesql @stmt = @ls_sql 
		,				   @params = @ls_params 
		,				   @ab_passes_validation = @lb_passes_validation OUTPUT 
		;

		IF @lb_passes_validation = 0
		BEGIN
			SET @ls_error_msg = N'@as_work_table_name.row_num must be a value between 1 and r inclusive for all rows, where r is the row count of the table.';
			RAISERROR(@ls_error_msg, 16, 1);
		END;
	/*******************************************************************************
	Determine the range of IDs to generate
	*******************************************************************************/
		SET @li_min_new_id = 
		(
			SELECT [next_id]
			FROM [config].[next_id] 
			WHERE [system_object_id] = @li_table_system_id
		);

		SET @li_max_new_id = @li_min_new_id + @li_num_ids_needed - 1;
			
	/*******************************************************************************
	Generate the IDs and an identifying row number
	*******************************************************************************/
		INSERT INTO #row_num_to_id
		(
			[row_num]
		,	[row_id]
		)
		SELECT 
			ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		,	n 
		FROM [config].[get_nums]
		(
			@li_min_new_id
		,	@li_max_new_id
		)
		;

	/*******************************************************************************
	Update the work table with the newly generated IDs
	*******************************************************************************/
		SET @ls_sql = 
		CONCAT 
		(
			'
			UPDATE W
			SET W.[row_id] = RNID.[row_id]
			FROM ', @as_work_table_name, N' AS W
				INNER JOIN #row_num_to_id AS RNID
				   	ON W.[row_num] = RNID.[row_num]
			;
			'
		);

		EXEC(@ls_sql);

	/*******************************************************************************
	Update [config].[next_id] for table receiving the object IDs 
	to the smallest ID not in the generated range
	*******************************************************************************/
		UPDATE [config].[next_id]
		SET [next_id] = @li_max_new_id + 1
		WHERE [system_object_id] = @li_table_system_id
		;

	END TRY
	BEGIN CATCH
		SET @ls_error_msg = 
			CONCAT( ERROR_MESSAGE(), NCHAR(13)
				  ,'Error Line: ', ERROR_LINE(), NCHAR(13)
				  ,'Error Procedure: ', ERROR_PROCEDURE()
				  );
		RAISERROR(@ls_error_msg, 16, 1);
	END CATCH;
END; 