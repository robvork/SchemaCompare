DROP PROCEDURE IF EXISTS [config].[p_sync_table];
GO

CREATE PROCEDURE [config].[p_sync_object_class]
(
	@as_object_class_current_values_table_name SYSNAME = NULL
,	@ai_object_class_id SYSNAME = NULL
,	@ai_instance_id INT = NULL
,	@ai_database_id INT = NULL
)
AS
/*
	-- Query all the rows in the current version of the object
	-- From the previous query, extract the [name] column
	-- Determine which rows in the [object] schema table have been inserted, deleted, and updated by matching on [name]
	-- Delete the deleted rows 
	-- Insert the inserted rows
	-- Update the updated rows

	We will use a merge statement since we need to do the classical insert/update/delete pattern

	Here's an example from T-SQL Querying:
	MERGE INTO dbo.Customers AS TGT -- define the source of data. will be @as_object_class_current_values_table_name in our case
	USING dbo.CustomersStage AS SRC -- define the target of data. will be the table corresponding to @ai_object_class_id in our case
	ON TGT.custid = SRC.custid -- define the matching condition. will be matched on instance_id, database_id, and name in our case
	WHEN MATCHED THEN -- what happens when the matching condition holds? like in the example, we update in our case
	UPDATE SET
	TGT.companyname = SRC.companyname,
	TGT.phone = SRC.phone,
	TGT.address = SRC.address
	WHEN NOT MATCHED THEN -- what happens for each row in the source that is not matched in the target? like in the example, we insert in our case
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
	WHEN NOT MATCHED BY SOURCE THEN -- what happens for each row in the target which is not matched in the source? like in the example, we delete in our case
	DELETE;

	so how will this be different from the example?
	1. we need to construct the column set dynamically at runtime  
	2. we need to filter the target table on instance_id and database_id in a CTE or temp table prior to MERGING. we don't want to update anything belonging to other instance_ids or databases

	1. static and dynamic elements in this procedure
	**static elements**
	target table
	source table
	matching condition
	WHEN NOT MATCHED BY SOURCE action

	**dynamic elements**
	WHEN MATCHED target and source column list (will be the same exact names but we won't update instance_id, database_id, object_id, or name)
	WHEN NOT MATCHED target insert column header and source column header

	to accomplish this dynamicism, we do the following	
		i. get the list of columns for object class @ai_object_class_id in [config].[object_class_property] for which is_enabled = true.
		   we can assume that is_enabled = 0 for [instance_id], [database_id], [object_id].
		   call this result set C.
		ii. concatenate C in 3 different ways:
			a) TGT.col = SRC.col for each col in C
			b) (col1, col2, ..., coln) for col1, col2, ... , coln in C
			c) SRC.col1, SRC.col2, ... , SRC.coln for col1, col2, ... coln in C

			this concatenation can be done in any order using cursors or a SELECT @var = val pattern

	2. instance/database-filtered object rows
	we need to do something like the following:
	WITH eligible_for_merge AS
	(
		SELECT * 
		FROM <target_table>
		WHERE [instance_id] = @ai_instance_id AND [database_id] = @ai_database_id
	)
	MERGE INTO eligible_for_merge AS TGT
	...

	---------------
	Combining the above, we can write the query as follows:
	WITH eligible_for_merge AS
	(
		SELECT * 
		FROM <target_table>
		WHERE [instance_id] = @ai_instance_id AND [database_id] = @ai_database_id
	)
	MERGE INTO eligible_for_merge AS TGT
	USING @as_object_class_current_values_table_name AS SRC
	ON TGT.[name] = SRC.[name]
	WHEN MATCHED THEN UPDATE
	<substatement_1_ii_a>
	WHEN NOT MATCHED THEN INSERT 
	<substatement_1_ii_b>
	WHEN NOT MATCHED BY SOURCE
	<substatement_1_ii_c>


*/
BEGIN
BEGIN TRY
	SET NOCOUNT ON;

	-- Declare local variables
	BEGIN
	DECLARE @ls_sql NVARCHAR(MAX); 
	DECLARE @ls_name_filter NVARCHAR(1000); 
	DECLARE @ls_error_msg NVARCHAR(MAX);
	DECLARE @ls_newline NCHAR(1); 
	DECLARE @ls_single_quote NCHAR(1);
	DECLARE @ls_object_class_table_schema_name SYSNAME;
	DECLARE @ls_object_class_table_name SYSNAME;
	DECLARE @ls_object_class_source NVARCHAR(MAX);
	DECLARE @ls_object_class_source_alias NVARCHAR(10);

	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  

	END;

	-- Initialize local variables
	BEGIN
	SET @ls_newline = NCHAR(13); 
	SET @li_error_severity = 16;
	SET @li_error_state = 1;
	SET @ls_single_quote = N'''';
	END;

	-- Declare temp tables
	BEGIN
	DROP TABLE IF EXISTS #object_class_column;

	CREATE TABLE #object_class_column
	(
		column_name SYSNAME NOT NULL PRIMARY KEY
	);

	END; 

	-- Validate/Set Instance in [config].[instance]
	BEGIN
	IF (@as_instance_name IS NULL AND @ai_instance_id IS NULL) 
		OR 
	   (@as_instance_name IS NOT NULL AND @ai_instance_id IS NOT NULL)
	BEGIN
		SET @ls_error_msg = N'Exactly one of @as_instance_name or @ai_instance_id must be specified';
		
		RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
	END;
	ELSE IF @as_instance_name IS NOT NULL
	BEGIN
		SET @ai_instance_id = 
		(
			SELECT [instance_id] 
			FROM [config].[instance] 
			WHERE [instance_name] = @as_instance_name
		);

		IF @ai_instance_id IS NULL
		BEGIN
			SET @ls_error_msg = 
			CONCAT 
			(
				@ls_single_quote
			,	@as_instance_name
			,	@ls_single_quote
			,	N' is not a recognized instance name'
			);

			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
		END;
	END; 
	ELSE IF @ai_instance_id IS NOT NULL
	BEGIN
		IF NOT EXISTS
		(
			SELECT * 
			FROM [config].[instance] 
			WHERE [instance_id] = @ai_instance_id
		)
		BEGIN
			SET @ls_error_msg = 
			CONCAT 
			(
				@ai_instance_id
			,	N' is not a valid instance ID'
			); 
		END; 
	END;
	END;

	-- Validate/Set Database in [config].[database]
	BEGIN
	IF (@as_database_name IS NULL AND @ai_database_id IS NULL) 
		OR 
	   (@as_database_name IS NOT NULL AND @ai_database_id IS NOT NULL)
	BEGIN
		SET @ls_error_msg = N'Exactly one of @as_database_name or @ai_database_id must be specified';
		
		RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
	END;
	ELSE IF @as_database_name IS NOT NULL
	BEGIN
		SET @ai_database_id = 
		(
			SELECT [database_id] 
			FROM [config].[database] 
			WHERE [database_name] = @as_database_name 
				  AND 
				  [instance_id] = @ai_instance_id
		);

		IF @ai_database_id IS NULL
		BEGIN
			SET @ls_error_msg = 
			CONCAT 
			(
				CONCAT 
				(
					@ls_single_quote
				,	@as_database_name
				,	@ls_single_quote
				) 
			,	N' is not a recognized database name for instance name '
			,	CONCAT 
				(
					@ls_single_quote
				,	@as_instance_name
				,	@ls_single_quote
				,	N' is not a recognized instance name'
				)
			);

			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
		END;
	END; 
	ELSE IF @ai_database_id IS NOT NULL
	BEGIN
		IF NOT EXISTS
		(
			SELECT * 
			FROM [config].[database] 
			WHERE [database_id] = @ai_database_id
				  AND 
				  [instance_id] = @ai_instance_id
		)
		BEGIN
			SET @ls_error_msg = 
			CONCAT 
			(
				@ai_database_id
			,	N' is not a valid database ID for instance ID '
			,	@ai_instance_id
			); 
		END; 
	END;
	END;

	-- Validate/Set Object Class in [config].[object_class]
	BEGIN
		IF (@as_object_class_name IS NULL AND @ai_object_class_id IS NULL) 
			OR 
		   (@as_object_class_name IS NOT NULL AND @ai_object_class_id IS NOT NULL)
		BEGIN
			SET @ls_error_msg = N'Exactly one of @as_object_class_name or @ai_object_class_id must be specified';
		
			RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
		END;
		ELSE IF @as_object_class_name IS NOT NULL
		BEGIN
			SET @ai_object_class_id = 
			(
				SELECT [object_class_id] 
				FROM [config].[object_class] 
				WHERE [object_class_name] = @as_object_class_name
			);

			IF @ai_object_class_id IS NULL
			BEGIN
				SET @ls_error_msg = 
				CONCAT 
				(
					@ls_single_quote
				,	@as_object_class_name
				,	@ls_single_quote
				,	N' is not a recognized object class name'
				);

				RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
			END;
		END; 
		ELSE IF @ai_object_class_id IS NOT NULL
		BEGIN
			IF NOT EXISTS
			(
				SELECT * 
				FROM [config].[object_class] 
				WHERE [object_class_id] = @ai_object_class_id
			)
			BEGIN
				SET @ls_error_msg = 
				CONCAT 
				(
					@ai_object_class_id
				,	N' is not a valid object class ID'
				); 
			END; 
		END; 
	END;

	-- Get object class schema, table, source, and source_alias from [config].[object_class]
	BEGIN
	SELECT 
		@ls_object_class_table_schema_name = [table_schema_name]
	,	@ls_object_class_table_name = [table_name]
	,	@ls_object_class_source = [object_class_source]
	,	@ls_object_class_source_alias = [object_class_source_alias]
	FROM [config].[object_class]
	WHERE object_class_id = @ai_object_class_id
	;
	END;

	-- Get column list of object class in [config].[object_class_property]
	BEGIN
	INSERT INTO #object_class_column
	SELECT [object_class_property_name] 
	FROM [config].[object_class_property] 
	WHERE [object_class_id] = @ai_object_class_id
	;
	END;

	-- Create table with same schema as the object class data table 
	SET @ls_sql = 
	CONCAT 
	(
		N'SELECT TOP 0 * 
		INTO #object_class_current 
		FROM ', @ls_object_class_table_schema_name, N'.', @ls_object_class_table_name, N';'
	);

	-- Query all the rows in the current version of the object
	-- From the previous query, extract the [name] column
	-- Determine which rows in the [object] schema table have been inserted, deleted, and updated by matching on [name]
	-- Delete the deleted rows 
	-- Insert the inserted rows
	-- Update the updated rows
	
	RETURN 0;
END TRY
BEGIN CATCH
	SET @ls_error_msg = 
	CONCAT 
	(
		'{', @ls_newline 		 
	,		 'ERROR MESSAGE: ', ERROR_MESSAGE(), @ls_newline
	,		 'ERROR PROCEDURE: ', ERROR_PROCEDURE(), @ls_newline 
	,		 'ERROR LINE: ', ERROR_LINE(), @ls_newline
	,		 'ERROR SEVERITY: ', ERROR_SEVERITY(), @ls_newline 
	,		 'ERROR STATE: ', ERROR_STATE(), @ls_newline
	,	'}'
	);
	
	SET @li_error_severity = ERROR_SEVERITY(); 
	SET @li_error_state = ERROR_STATE();
	RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);

	RETURN 1;
END CATCH
END;
GO