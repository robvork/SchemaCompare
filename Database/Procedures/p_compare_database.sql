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
	,	[path] NVARCHAR(MAX) NOT NULL
	,	[depth] INT NOT NULL
	,	[has_match] BIT NULL
	--,	CONSTRAINT pk_compare_staging 
	--	PRIMARY KEY 
	--	(
	--		[instance_id]
	--	,	[database_id]
	--	,	[path]
	--	)
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
	END;



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




