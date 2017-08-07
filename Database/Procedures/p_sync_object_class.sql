DROP PROCEDURE IF EXISTS [config].[p_sync_object_class];
GO

CREATE PROCEDURE [config].[p_sync_object_class]
(
	@as_instance_name SYSNAME = NULL
,
	@ai_instance_id INT = NULL
,
	@as_database_name SYSNAME = NULL
,
	@ai_database_id INT = NULL
,	
	@as_object_class_name [config].[NAME] = NULL
,
	@ai_object_class_id INT = NULL
,
	@as_input_table_name SYSNAME = NULL
,
	@ai_debug_level INT = 1
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
	MERGE INTO dbo.Customers AS T -- define the source of data. will be @as_object_class_current_values_table_name in our case
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
	WITH target_rows AS
	(
		SELECT * 
		FROM <target_table>
		WHERE [instance_id] = @ai_instance_id AND [database_id] = @ai_database_id
	)
	MERGE INTO target_rows AS T
	...

	---------------
	Combining the above, we can write the query as follows:
	WITH target_rows AS
	(
		SELECT * 
		FROM <target_table>
		WHERE [instance_id] = @ai_instance_id AND [database_id] = @ai_database_id
	)
	MERGE INTO target_rows AS T
	USING @as_object_class_current_values_table_name AS SRC
	ON TGT.[name] = SRC.[name]
	WHEN MATCHED THEN UPDATE
	<substatement_1_ii_a>
	WHEN NOT MATCHED THEN INSERT 
	<substatement_1_ii_b>
	<substatement_1_ii_c>
	WHEN NOT MATCHED BY SOURCE
	DELETE


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
	DECLARE @ls_comma NCHAR(1);
	DECLARE @ls_single_quote NCHAR(1);
	DECLARE @ls_object_class_table_schema_name SYSNAME;
	DECLARE @ls_object_class_table_name SYSNAME;
	DECLARE @ls_object_class_source NVARCHAR(MAX);
	DECLARE @ls_object_class_source_alias NVARCHAR(10);
	DECLARE @ls_standard_metadata_key_name_instance SYSNAME;
	DECLARE @ls_standard_metadata_key_name_database SYSNAME;
	
	DECLARE @ls_sql_merge_update_set_statements NVARCHAR(MAX);
	DECLARE @ls_sql_merge_insert_target_header NVARCHAR(MAX);
	DECLARE @ls_sql_merge_insert_source_header NVARCHAR(MAX);
	DECLARE @ls_key_column SYSNAME;
	DECLARE @ls_val_column SYSNAME;

	DECLARE @ls_sql_merge_target NVARCHAR(MAX);
	DECLARE @ls_sql_merge_source NVARCHAR(MAX);
	DECLARE @ls_sql_merge_matching_condition NVARCHAR(MAX);
	DECLARE @ls_sql_merge_when_matched NVARCHAR(MAX);
	DECLARE @ls_sql_merge_when_not_matched_by_target NVARCHAR(MAX);
	DECLARE @ls_sql_merge_when_not_matched_by_source NVARCHAR(MAX);

	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;  

	DECLARE @lb_input_table_has_required_columns BIT;

	END;

	-- Initialize local variables
	BEGIN
	SET @ls_newline = NCHAR(13); 
	SET @li_error_severity = 16;
	SET @li_error_state = 1;
	SET @ls_single_quote = N'''';
	SET @ls_comma = N',';
	SET @ls_standard_metadata_key_name_instance = 
	(
		SELECT 
			[standard_metadata_key_name] 
		FROM 
			[config].[standard_metadata_key]
		WHERE 
			[standard_metadata_key_name] LIKE N'%instance%'
	);
	SET @ls_standard_metadata_key_name_database = 
	(
		SELECT 
			[standard_metadata_key_name] 
		FROM 
			[config].[standard_metadata_key]
		WHERE 
			[standard_metadata_key_name] LIKE N'%database%'
	);


	END;

	-- Declare temp tables
	BEGIN
	DROP TABLE IF EXISTS #object_class_column;

	CREATE TABLE #object_class_property
	(
		property_name SYSNAME NOT NULL PRIMARY KEY
	,	is_metadata_key BIT NOT NULL
	,	is_object_key BIT NOT NULL
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

	-- Get list of columns for object class
	INSERT INTO #object_class_property
	(
		property_name 
	,	is_metadata_key
	,	is_object_key 
	)
	SELECT 
		[object_class_property_name]
	,	[object_class_property_is_metadata_key]
	,	[object_class_property_is_object_key]
	FROM 
		[config].[object_class_property]
	WHERE 
		[object_class_id] = @ai_object_class_id
		AND
		[object_class_property_name] NOT IN (@ls_standard_metadata_key_name_instance, @ls_standard_metadata_key_name_database)
		AND
		[object_class_property_is_enabled] = 1
	;

	IF @ai_debug_level > 1
	BEGIN
		SELECT '#object_class_property';
		SELECT * FROM #object_class_property;
	END; 

	-- Validate that [config].[object_class_property defines at least one key column for the chosen object class
	BEGIN
	IF NOT EXISTS(SELECT * FROM #object_class_property WHERE [is_metadata_key] = 1)
	BEGIN
		SET @ls_error_msg = CONCAT(N'[config].[object_class_property] does not define a key for the chosen object class.'
									  ,N'At least one key column must be specified.');
		RAISERROR(@ls_error_msg, @li_error_severity, @li_error_state);
	END;
	END;

	-- Get schema and table name for chosen object class
	SELECT 
		@ls_object_class_table_schema_name = [table_schema_name]
	,	@ls_object_class_table_name = [table_name]
	FROM [config].[object_class]
	WHERE object_class_id = @ai_object_class_id
	;

	/****************  Generate MERGE INTO target definition code ****************/
	-- we determined the schema and table containing the merge target rows above.
	-- we further need to filter down to just those rows belonging to the specified instance and server. 
	-- by defining a CTE 'target_rows' satisfying this condition, we can isolate our work to just those rows.
	SET @ls_sql_merge_target = 
	CONCAT 
	(
		N'WITH target_rows AS 
		(
			SELECT * 
			FROM [', @ls_object_class_table_schema_name, N'].[', @ls_object_class_table_name, N'] 
			WHERE', QUOTENAME(@ls_standard_metadata_key_name_instance), N' = ', @ai_instance_id
			, N' AND ', QUOTENAME(@ls_standard_metadata_key_name_database), N' = ', @ai_database_id, N'
		)
		MERGE INTO target_rows AS TGT'
	) 
	; 

	IF @ai_debug_level > 1
		SELECT 'merge_target' AS [description], @ls_sql_merge_target AS 'code'

	/****************  Generate USING source definition code ****************/
	SET @ls_sql_merge_source = 
	CONCAT 
	(
		N'USING ', @as_input_table_name ,' AS SRC'
	)
	;
	
	IF @ai_debug_level > 1
		SELECT 'merge_source' AS [description], @ls_sql_merge_source AS 'code'

	/****************  Generate ON <boolean_expression> matching condition code ****************/
	BEGIN
		-- SQL of form SRC.key1 = TGT.key1, SRC.key2 = TGT.key2, ... , SRC.keyn = TGT.keyn 
		-- for keys key1, key2, ... , keyn in #object_class_property
		-- i.e. property_name values for which is_metadata_key = 1

	DECLARE key_column_cursor CURSOR LOCAL SCROLL
	FOR 
	SELECT [property_name] 
	FROM #object_class_property
	WHERE [is_metadata_key] = 1
	;

	OPEN key_column_cursor;

	FETCH NEXT FROM key_column_cursor
	INTO @ls_key_column;

	SET @ls_sql_merge_matching_condition = N'';
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @ai_debug_level > 1
			SELECT @ls_key_column AS '@ls_key_column'

		SET @ls_sql_merge_matching_condition +=
		CONCAT 
		(
			@ls_newline, N'AND SRC.', @ls_key_column, N'= TGT.', @ls_key_column
			--@ls_newline, N'AND SRC.', @ls_key_column, N' COLLATE DATABASE_DEFAULT = TGT.', @ls_key_column, N' COLLATE DATABASE_DEFAULT'
		); 

		FETCH NEXT FROM key_column_cursor
		INTO @ls_key_column; 
	END; 
	END;

	SET @ls_sql_merge_matching_condition = 
	CONCAT
	(
		N'ON '
		-- extract the string beginning at the first occurrence of S
		-- this omits the first occurrence of 'AND'
	,	SUBSTRING
		(
			@ls_sql_merge_matching_condition
		,	CHARINDEX(N'S', @ls_sql_merge_matching_condition)
		,	LEN(@ls_sql_merge_matching_condition) 
		)
	)

	/****************  Generate WHEN MATCHED THEN UPDATE code ****************/
	-- SQL of the form TGT.val1 = SRC.val1, TGT.val2 = SRC.val2, ... , TGT.valm = SRC.valm 
	-- for vals val1, val2, ... , valm in #object_class_property
	-- i.e. property name values for which is_metadata_key = 0
	BEGIN 
	DECLARE val_column_cursor CURSOR LOCAL SCROLL
	FOR 
	SELECT [property_name] 
	FROM #object_class_property
	WHERE [is_metadata_key] = 0
	;

	OPEN val_column_cursor;

	FETCH NEXT FROM val_column_cursor
	INTO @ls_val_column;

	SET @ls_sql_merge_update_set_statements = N'';
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @ls_sql_merge_update_set_statements += 
		CONCAT 
		(
			@ls_newline
		,	@ls_comma,	N' '
		,	N'TGT.', @ls_val_column, N' = ' 
		,	N'SRC.', @ls_val_column
		); 

		FETCH NEXT FROM val_column_cursor
		INTO @ls_val_column;
	END;

	-- Do not create an update statement if there are no value columns to update
	IF @ls_sql_merge_update_set_statements <> N''
	BEGIN
		SET @ls_sql_merge_when_matched = 
		CONCAT 
		(
			N'WHEN MATCHED THEN UPDATE SET '
		,	@ls_newline 
			-- extract the substring starting at the first occurrence of TGT.
			-- this omits the first newline, comma, and space
		,	SUBSTRING 
			(
				@ls_sql_merge_update_set_statements
			,	CHARINDEX('T', @ls_sql_merge_update_set_statements)
			,	LEN(@ls_sql_merge_update_set_statements)
			)
		); 
	END;
	
	END;
	IF @ai_debug_level > 1
		SELECT 'WHEN MATCHED' AS [description], @ls_sql_merge_when_matched AS 'code'
	-- Generate insert values for rows in S which are not found in T
		-- Note: since we validated that there is at least one column, the source and target headers here will each be nonempty
	-- Target header
		-- (key1, key2, ... , keyn, val1, val2, ... , valm) 
			-- for keyi and valj in #object_class_property with is_metadata_key = 1 and 0 respectively
	BEGIN
	BEGIN 
	SET @ls_sql_merge_insert_target_header = CAST(N'' AS NVARCHAR(MAX));

	FETCH FIRST FROM key_column_cursor 
	INTO @ls_key_column; 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @ls_sql_merge_insert_target_header = 
		CONCAT 
		(
			@ls_sql_merge_insert_target_header
		,	N', ', @ls_key_column
		); 

		FETCH NEXT FROM key_column_cursor 
		INTO @ls_key_column;
	END; 

	FETCH FIRST FROM val_column_cursor 
	INTO @ls_val_column; 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @ls_sql_merge_insert_target_header = 
		CONCAT 
		(
			@ls_sql_merge_insert_target_header
		,	N', ', @ls_val_column
		); 

		FETCH NEXT FROM val_column_cursor 
		INTO @ls_val_column; 
	END;

	SET @ls_sql_merge_insert_target_header = 
	CONCAT 
	(
		N'('
		-- extract the substring starting at the character after the first occurrence of ','
		-- this omits the first comma and space
	,	@ls_standard_metadata_key_name_instance
	,	N','
	,	@ls_standard_metadata_key_name_database
	,	N','
	,	CAST(SUBSTRING
		(
			@ls_sql_merge_insert_target_header
		,	CHARINDEX(N',', @ls_sql_merge_insert_target_header) + 1
		,	LEN(@ls_sql_merge_insert_target_header)
		) AS NVARCHAR(MAX))
	,	N')'
	); 
	END;
	IF @ai_debug_level > 1
		SELECT 'INSERT target header' AS [description], @ls_sql_merge_insert_target_header AS 'code'

	-- Source header
	-- SRC.key1, SRC.key2, ... , SRC.keyn, SRC.val1, SRC.val2, ... , SRC.valm 
		-- for keyi and valj in #object_class_property with is_metadata_key = 1 and 0 respectively
	BEGIN

	-- move cursor back to the first key column
	FETCH FIRST FROM key_column_cursor 
	INTO @ls_key_column; 

	SET @ls_sql_merge_insert_source_header = CAST(N'' AS NVARCHAR(MAX));
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @ls_sql_merge_insert_source_header =
		CONCAT 
		(
			@ls_sql_merge_insert_source_header
		,	N', SRC.', @ls_key_column
		); 

		FETCH NEXT FROM key_column_cursor 
		INTO @ls_key_column;
	END; 

	-- move cursor back to the first value column
	FETCH FIRST FROM val_column_cursor 
	INTO @ls_val_column; 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @ls_sql_merge_insert_source_header =  
		CONCAT 
		(
			@ls_sql_merge_insert_source_header
		,	N', SRC.', @ls_val_column
		); 

		FETCH NEXT FROM val_column_cursor 
		INTO @ls_val_column;
	END; 
	
	-- extract the substring starting at the character after the first occurrence of ',', as we did above
	SET @ls_sql_merge_insert_source_header = 
	CONCAT 
	(
		N'VALUES' 
	,	N'('
	,	@ai_instance_id
	,	N', '
	,	@ai_database_id
	,	N', '
	,	CAST(SUBSTRING 
		(
			@ls_sql_merge_insert_source_header
		,	CHARINDEX(N',', @ls_sql_merge_insert_source_header) + 1
		,	LEN(@ls_sql_merge_insert_source_header)
		) AS NVARCHAR(MAX))
	,	N')'
	)
	;
	
	IF @ai_debug_level > 1
		SELECT 'INSERT source header' AS [description], @ls_sql_merge_insert_source_header AS 'code'

	SET @ls_sql_merge_when_not_matched_by_target = 
	CONCAT 
	(
		N'WHEN NOT MATCHED BY TARGET THEN INSERT'
	,	@ls_newline 
	,	@ls_sql_merge_insert_target_header
	,	@ls_newline
	,	@ls_sql_merge_insert_source_header
	); 
	END;
	END;

	IF @ai_debug_level > 1
		SELECT 'WHEN NOT MATCHED BY TARGET code' AS [description], @ls_sql_merge_when_not_matched_by_target AS 'code'

	/****************  Generate WHEN NOT MATCHED THEN DELETE code ****************/
	BEGIN
	SET @ls_sql_merge_when_not_matched_by_source = 
	CONCAT 
	(
		N'WHEN NOT MATCHED BY SOURCE THEN', @ls_newline
	,	N'DELETE'
	);
	END;

	IF @ai_debug_level > 1
		SELECT 'WHEN NOT MATCHED BY SOURCE code' AS [description], @ls_sql_merge_when_not_matched_by_source AS 'code'
	
	-- Check that input table has all enabled columns with the appropriate data types
	-- Query all the rows in the current version of the object
	-- From the previous query, extract the [name] column
	-- Determine which rows in the [object] schema table have been inserted, deleted, and updated by matching on [name]
	-- Delete the deleted rows 
	-- Insert the inserted rows
	-- Update the updated rows

	-- Generate final merge statement
	/*
	The code generated is of the following form. 
	Dashed lines added here separate the contributions of each of the variables in the concatenation
	---------------------------------------------------------------------------
	WITH target_rows AS
	(
		SELECT * 
		FROM <target_table>
		WHERE [instance_id] = @ai_instance_id AND [database_id] = @ai_database_id
	)
	MERGE INTO target_rows AS T
	---------------------------------------------------------------------------
	USING @as_object_class_current_values_table_name AS SRC
	---------------------------------------------------------------------------
	ON SRC.key = TGT.key foreach key column 'key'
	---------------------------------------------------------------------------
	WHEN MATCHED THEN UPDATE
	TGT.val = SRC.val foreach value column 'val' 
	---------------------------------------------------------------------------
	WHEN NOT MATCHED THEN INSERT 
	(key1, key2, ... , keyn, val1, val2, ... , valm) for key column keyi and val column valj
	VALUES (SRC.key1, SRC.key2, ... , SRC.keyn, SRC.val1, SRC.val2, ... , SRC.valm) for keyi and valj matching above
	---------------------------------------------------------------------------
	WHEN NOT MATCHED BY SOURCE THEN
	DELETE
	---------------------------------------------------------------------------
	*/
	
	--SET @ls_sql = N'';
	--SET @ls_sql = CONCAT(@ls_sql, @ls_sql_merge_target, @ls_newline);
	--SET @ls_sql = CONCAT(@ls_sql, @ls_sql_merge_source, @ls_newline);
	--SET @ls_sql = CONCAT(@ls_sql, @ls_sql_merge_matching_condition, @ls_newline);
	--SET @ls_sql = CONCAT(@ls_sql, CAST(SUBSTRING(@ls_sql_merge_when_matched, 1, 3000) AS NVARCHAR(MAX)));
	--SET @ls_sql = CONCAT(@ls_sql, CAST(SUBSTRING(@ls_sql_merge_when_matched, 3001, 3999) AS NVARCHAR(MAX)), @ls_newline);
	--SET @ls_sql = CONCAT(@ls_sql, @ls_sql_merge_when_not_matched_by_target, @ls_newline);
	--SET @ls_sql = CONCAT(@ls_sql, @ls_sql_merge_when_not_matched_by_source, @ls_newline);
	--SET @ls_sql = CONCAT(@ls_sql, N';');

	
	--SELECT * 
	--FROM 
	--(
	--	VALUES 
	--	('merge_target', LEN(@ls_sql_merge_target))
	--,	('merge_source', LEN(@ls_sql_merge_source))
	--,	('merge_matching_condition', LEN(@ls_sql_merge_matching_condition))
	--,	('merge_when_matched', LEN(@ls_sql_merge_when_matched))
	--,	('merge_not_matched_by_target', LEN(@ls_sql_merge_when_not_matched_by_target))
	--,	('merge_not_matched_by_source', LEN(@ls_sql_merge_when_not_matched_by_source))
	--) AS lengths(descr, str_length)
	--RETURN 0;

	SET @ls_sql = 
	CONCAT 
	(
		CAST(@ls_sql_merge_target AS NVARCHAR(MAX))							, @ls_newline 
	,	CAST(@ls_sql_merge_source AS NVARCHAR(MAX))							, @ls_newline 
	,	CAST(@ls_sql_merge_matching_condition AS NVARCHAR(MAX))				, @ls_newline 
	,	CAST(@ls_sql_merge_when_matched AS NVARCHAR(MAX))					, @ls_newline 
	,	CAST(@ls_sql_merge_when_not_matched_by_target AS NVARCHAR(MAX))		, @ls_newline 
	,	CAST(@ls_sql_merge_when_not_matched_by_source AS NVARCHAR(MAX))     , @ls_newline 
	,	N';'
	) 
	; 

	-- Perform the merge
	BEGIN 
	IF @ai_debug_level > 0
	BEGIN
		PRINT CONCAT(N'Executing the following in dynamic SQL:', @ls_newline, @ls_sql);
		IF @ai_debug_level > 1
		BEGIN
			SELECT @ls_sql AS '@ls_sql';
		END; 
	END; 

	EXEC(@ls_sql);
	END;

	CLOSE val_column_cursor;
	CLOSE key_column_cursor; 
	DEALLOCATE val_column_cursor;
	DEALLOCATE key_column_cursor;

	RETURN 0;
END TRY
BEGIN CATCH
	IF CURSOR_STATUS('local', 'val_column_cursor') > -1
		CLOSE val_column_cursor;

	IF CURSOR_STATUS('local', 'key_column_cursor') > -1
		CLOSE key_column_cursor;

	IF CURSOR_STATUS('local', 'val_column_cursor') > -3
		DEALLOCATE val_column_cursor;

	IF CURSOR_STATUS('local', 'key_column_cursor') > -3
		DEALLOCATE key_column_cursor;


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

--DROP TABLE IF EXISTS #current; 

--SELECT *
--INTO #current 
--FROM sys.databases 


--EXEC [config].[p_sync_object_class]
--	@as_object_class_name = 'database'
--,	@as_input_table_name = '#current'
--,	@ai_debug_level = 2
--,   @as_instance_name = N'ASPIRING\SQL16'
--,	@as_database_name = 'WideWorldImporters'
--;

--SELECT * FROM [object].[database]
--SELECT * FROM [config].[database]
