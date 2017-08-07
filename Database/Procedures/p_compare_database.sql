DROP PROCEDURE IF EXISTS [config].[p_compare_database];
GO

CREATE PROCEDURE [config].[p_compare_database]
(
	@as_instance_name_left SYSNAME
,	@as_database_name_left SYSNAME

,	@as_instance_name_right SYSNAME
,	@as_database_name_right SYSNAME

,	@ab_recurse BIT
,	@ai_depth INT = -1

,	@ai_debug_level INT = 0
)
AS
BEGIN
BEGIN TRY
	SET NOCOUNT ON;
	DECLARE @ls_sql NVARCHAR(MAX); 
	DECLARE @ls_name_filter NVARCHAR(1000); 
	DECLARE @ls_error_msg NVARCHAR(MAX);
	DECLARE @ls_newline NCHAR(1); 
	DECLARE @li_error_severity INT;
	DECLARE @li_error_state INT;
	DECLARE @li_row_count INT;
	DECLARE @li_instance_id_left INT;
	DECLARE @li_database_id_left INT;
	DECLARE @li_instance_id_right INT;
	DECLARE @li_database_id_right INT;
	DECLARE @li_object_class_id INT;
	DECLARE @li_current_depth INT;
	DECLARE @ls_standard_metadata_key_name_instance SYSNAME;
	DECLARE @ls_standard_metadata_key_name_database SYSNAME;

	SET @li_instance_id_left = 
	(
		SELECT [instance_id] 
		FROM [config].[instance] 
		WHERE [instance_name] = @as_instance_name_left
	);

	IF @li_instance_id_left IS NULL
		RAISERROR(N'Invalid left instance name', 16, 1);

	SET @li_database_id_left = 
	(
		SELECT [database_id] 
		FROM [config].[database] 
		WHERE [database_name] = @as_database_name_left
			  AND 
			  [instance_id] = @li_instance_id_left
	);

	IF @li_database_id_left IS NULL
		RAISERROR(N'Invalid left database name', 16, 1);

	SET @li_instance_id_right = 
	(
		SELECT [instance_id] 
		FROM [config].[instance] 
		WHERE [instance_name] = @as_instance_name_right
	);

	IF @li_instance_id_right IS NULL
		RAISERROR(N'Invalid right instance name', 16, 1);

	SET @li_database_id_right = 
	(
		SELECT [database_id] 
		FROM [config].[database] 
		WHERE [database_name] = @as_database_name_right
			  AND 
			  [instance_id] = @li_instance_id_right
	);

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

	IF @li_database_id_right IS NULL
		RAISERROR(N'Invalid right database name', 16, 1);

	DROP TABLE IF EXISTS #compare_staging;

	CREATE TABLE #compare_staging
	(
		[schemacompare_source_instance_id] INT NOT NULL
	,	[schemacompare_source_database_id] INT NOT NULL
	,	[parent_object_class_id] INT NULL
	,	[parent_object_metadata_key] INT NULL
	,	[object_class_id] INT NOT NULL
	,	[object_metadata_key] INT NOT NULL
	,	[path] NVARCHAR(2000) NOT NULL
	,	[depth] INT NOT NULL
	,	[has_match] BIT NULL
	,	CONSTRAINT pk_compare_staging 
		PRIMARY KEY 
		(
			[schemacompare_source_instance_id]
		,	[schemacompare_source_database_id]
		,	[path]
		)
	);

	CREATE TABLE #object_linking_query
	(
		[object_class_id] INT NOT NULL
	,	[subobject_class_id] INT NOT NULL
	,	[depth] INT NOT NULL
	,	[query] NVARCHAR(MAX) NOT NULL
	,	CONSTRAINT pk_object_linking_query 
		PRIMARY KEY
		(
			[object_class_id]
		,	[subobject_class_id]
		,	[depth]
		)
	);

	IF @ai_depth < 0 
		SET @ai_depth = (SELECT COUNT(*) FROM [config].[object_class]);

	INSERT INTO #compare_staging
	(
		[schemacompare_source_instance_id]
	,	[schemacompare_source_database_id] 
	,	[parent_object_class_id]
	,	[parent_object_metadata_key]
	,	[object_class_id]
	,	[object_metadata_key]
	,	[path] 
	,	[depth] 
	,	[has_match]
	)
	VALUES 
	(
		@li_instance_id_left
	,	@li_database_id_left
	,	NULL 
	,	NULL 
	,	(
			 SELECT [object_class_id] 
			 FROM [config].[object_class] 
			 WHERE [object_class_name] = N'Database'
		)
	,	(
			SELECT [database_id] 
			FROM [object].[database] 
			WHERE [database_name] = @as_database_name_left
				  AND 
				  [schemacompare_source_instance_id] = @li_instance_id_left
				  AND 
				  [schemacompare_source_database_id] = @li_database_id_left 
		)
	,	N'.'
	,	0
	,	1
	)

	,
	
	(
		@li_instance_id_right
	,	@li_database_id_right
	,	NULL 
	,	NULL 
	,	(
			 SELECT [object_class_id] 
			 FROM [config].[object_class] 
			 WHERE [object_class_name] = N'Database'
		)
	,	(
			SELECT [database_id] 
			FROM [object].[database] 
			WHERE [database_name] = @as_database_name_right
				  AND 
				  [schemacompare_source_instance_id] = @li_instance_id_right
				  AND 
				  [schemacompare_source_database_id] = @li_database_id_right 
		)
	,	N'.'
	,	0
	,	1
	)
	;

	IF @ai_debug_level > 1
	BEGIN
		SELECT '#compare_staging after depth 0 insert';
		SELECT * FROM #compare_staging;
	END;
	
	SET @li_current_depth = 0;
	WHILE @li_current_depth < @ai_depth
	BEGIN
		WITH rows_at_current_depth AS
		(
			SELECT * 
			FROM #compare_staging
			WHERE [depth] = @li_current_depth
		)
		, object_classes_at_current_depth AS
		(
			SELECT DISTINCT [object_class_id] 
			FROM rows_at_current_depth
		)
		, object_class_mapping AS
		(
			SELECT 
				OCCD.[object_class_id]
			,	O2SO.[subobject_class_id]
			FROM 
				object_classes_at_current_depth AS OCCD
			INNER JOIN 
				[config].[object_to_subobject] AS O2SO
					ON OCCD.object_class_id = O2SO.object_class_id
		)
		, object_class_to_table AS
		(
			SELECT 
				OC.[object_class_id]
			,	CONCAT(QUOTENAME(OC.[table_schema_name]), '.', QUOTENAME(OC.[table_name])) AS schema_qualified_table_name
			FROM [config].[object_class] AS OC
		)
		, object_class_to_key AS
		(
			SELECT 
				OC.[object_class_id] 
			,	MK.[metadata_key_column_name]
			,	OK.[object_key_column_name]
			FROM 
				[config].object_class AS OC
			INNER JOIN
				[config].[object_class_metadata_key] AS MK
					ON OC.[object_class_id] = MK.[object_class_id] AND MK.is_parent_metadata_key = 0
			INNER JOIN 
				[config].[object_class_object_key] AS OK
					ON OC.[object_class_id] = OK.[object_class_id]
		)
		, object_to_subobject_fields 
		AS
		(
			SELECT * 
			FROM object_class_mapping AS OCM
			INNER JOIN object_class 
		)

		--, object_to_subobject_insert_statement AS
		--(
		--	SELECT 
		--		OCM.[object_class_id] 
		--	,	OCM.[subobject_class_id] 
		--	,	
				
		--	FROM object_class_mapping AS OCM 
			
		--) 

		INSERT INTO #compare_staging
		(
			[parent_object_class_id]
		,	[parent_object_metadata_key]
		,	[object_class_id]
		,	[object_metadata_key]
		,	[path] 
		,	[depth] 
		)
		SELECT 
			curr.[object_class_id]
		,	curr.[object_metadata_key] 
		,	OCM.[subobject_class_id]
		,	SOMK.[object_metadata_key_name]
		,	CONCAT(curr.path, N'/', SOT.SO.object_key)
		,	curr.depth + 1 
	END

		-- for each row r at depth = @li_current_depth:
		--		let c be the object class with object class id r.object_class_id
		--		join c to its subobject classes sc in [config].[object_to_subobject]
		--		for each object class sc which is a subobject class of c:
		--			determine rows r' in [sc.table_schema_name].[sc.table_name] which match r.object_metadata_key
		--			and which have the same standard metadata key as r (same sc_source_instance and sc_source_db)
		--			for each r', the object of object class sc which is a subobject of r, an object of object class c:
		--				append one row to #compare_staging having the following fields:
		--					schemacompare_source_instance_id = r.schemacompare_source_instance_id
		--					schemacompare_source_database_id = r.schemacompare_source_database_id
		--					parent_object_class_id = r.object_class_id
		--					parent_object_metadata_key = r.object_metadata_key
		--					object_class_id = sc.object_class_id
		--					object_metadata_key = r'.object_metadata_key
		--					depth = r.depth + 1
		--					path = r.path + "/" + r'.object_key

		-- for each row r at depth = @li_current_depth:
		-- update has_match as follows:
		--	  if r.sc_source_instance_id = left source instance and r.sc_source_db_id = left db
		--		 set has_match = 1 if there is a row r' with 
		--			r'.sc_source_instance_id = right source instance and r'.sc_source_db_id = right source instance
		--			AND 
		--			r'.path = r.path
		--		 set has_match = 0 if there is no such row
		RETURN 0;
	END;

	-- after the loop has finished executing, #compare_staging can be decomposed as follows:
	--	#compare_staging = R_left 
	--					   UNION 
	--					   R_common 
	--					   UNION 
	--					   R_right
	-- Where R_left   is the set of rows with has_match = 0 and (sc_source_instance, sc_source_db) = (left_inst, left_db)
	--		 R_right  is the set of rows with has_match = 0 and (sc_source_instance, sc_source_db) = (right_inst, right_db)
	--		 R_common is the set of rows with has_match = 1
	-- For each r_l in R_left
	--	  let c be the object class of r_l
	--	  let D be the schema-qualified diff table of c
	--	  output to D a row with metadata key = r_l.metadata_key
	--							 side_indicator "<"
	--							 has_match = 0
	--							 left standard key = left key
	--							 right standard key = right key
	--							 diff_column = NULL
	--							 diff_value = NULL
	-- Similarly, 
	-- For each r_r in R_right
	--	  let c be the object class of r_l
	--	  let D be the schema-qualified diff table of c
	--	  output to D a row with metadata key = r_r.metadata_key
	--							 side_indicator ">"
	--							 has_match = 0
	--							 left standard key = left key
	--							 right standard key = right key
	--							 diff_column = NULL
	--							 diff_value = NULL
	-- Given R_common, determine a derived set R_common_pairs = {(r_left, r_right) : r_left in R_common and r_right in R_common and 
	--															  r_left.path = r_right.path
	--															}
	-- For each pair (r_l, r_r) in R_common_pairs
	--	  since there is a path match, the object in each part of the match belongs to some single object class c
	--	  let D be the schema-qualified diff table of c
	--	  let P be the set of enabled non-key rows of c
	--	  let val_l be the values of P for the object of object class r_l.object_class and with r_l's metadata key
	--		 unpivoted to the form (<key>, <val>), where <key> is in P and <val> is the val of <key> for the object
	--	  let val_r be the values of P for the object of object class r_r.object_class and with r_r's metadata key
	--		 unpivoted to the form (<key>, <val>), where <key> is in P and <val> is the val of <key> for the object
	--	  let val_diff_l be the the set {(<key>, <val_l>) : (<key>, <val_l>) is in val_l and (<key>, <val_r>) is in val_r
	--									 and <val_l> != <val_r>
	--									}
	--	  let val_diff_r be the set {(<key>, <val_r>) : (<key>, <val_r>) is in val_r and (<key>, <val_l>) is in val_l
	--									 and <val_l> != <val_r>
	--									}
	--	  insert into D rows with metadata key val_l.key
	--										   side_indicator "<"
	--										   left standard key = left key
	--										   right standard key = right key
	--										   diff_column = <key>
	--										   diff_value = <val>
	--	  Similarly
	--	  insert into D rows with metadata key val_r.key
	--										   side_indicator ">"
	--										   left standard key = left key
	--										   right standard key = right key
	--										   diff_column = <key>
	--										   diff_value = <val>




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
END CATCH; 
END;

GO

EXEC [config].[p_compare_database]
	@as_instance_name_left = N'ASPIRING\SQL16'
,	@as_database_name_left = N'WideWorldImporters'
,	@as_instance_name_right = N'ASPIRING\SQL16' 
,	@as_database_name_right = N'sample_db'
,	@ab_recurse = 1
,	@ai_depth = 10
,	@ai_debug_level = 2




