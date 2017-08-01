DROP PROCEDURE IF EXISTS [object].[p_compare_object];
GO

CREATE PROCEDURE [object].[p_compare_object]
(
	@as_instance_name_left SYSNAME
,	@as_database_name_left SYSNAME
,	@as_object_name_left SYSNAME = NULL

,	@as_instance_name_right SYSNAME
,	@as_database_name_right SYSNAME
,	@as_object_name_right SYSNAME = NULL

,	@as_object_class_name SYSNAME = N'database'
,	@ab_recurse BIT = 0
,	@ai_depth INT = -1
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
  
	SET @ls_newline = NCHAR(13); 

	IF @ai_depth < 0
		SET @ai_depth = 
		(
			SELECT COUNT(*) 
			FROM [config].[object_class]
		)

	SET @li_instance_id_left = 
	(
		SELECT [instance_id] 
		FROM [config].[instance] 
		WHERE [instance_name] = @as_instance_name_left
	);
	
	IF @li_instance_id_left IS NULL
		RAISERROR(N'Left instance name is not valid', 16, 1);

	SET @li_database_id_left = 
	(
		SELECT [database_id] 
		FROM [config].[database] 
		WHERE [instance_id] = @li_instance_id_left
	);

	IF @li_database_id_left IS NULL
		RAISERROR(N'Left database name is not valid', 16, 1);

	SET @li_instance_id_right = 
	(
		SELECT [instance_id] 
		FROM [config].[instance] 
		WHERE [instance_name] = @as_instance_name_right
	);

	IF @li_instance_id_right IS NULL
		RAISERROR(N'Right instance name is not valid', 16, 1);

	SET @li_database_id_right = 
	(
		SELECT [database_id] 
		FROM [config].[database] 
		WHERE [instance_id] = @li_instance_id_right
	);

	IF @li_database_id_right IS NULL
		RAISERROR(N'Right database name is not valid', 16, 1);

	SET @li_object_class_id = 
	(
		SELECT [object_class_id] 
		FROM [config].[object_class]
		WHERE [object_class_name] = @as_object_class_name
	);

	IF @li_object_class_id IS NULL
		RAISERROR(N'Object class name is not valid', 16, 1);

	DROP TABLE IF EXISTS #diff_work_table 

	CREATE TABLE #diff_work_table
	(
		[instance_id] INT 
	,	[database_id] INT
	,	[base_object_name] SYSNAME 
	,	[hierarchy_path] NVARCHAR(MAX)
	,	[depth] INT
	,	[object_class_id] INT
	,	PRIMARY KEY 
		(
			[instance_id]
		,	[database_id] 
		,	[base_object_name]
		,	[hierarchy_path]
		)
	);

	INSERT INTO #diff_work_table
	(
		[instance_id]  
	,	[database_id] 
	,	[base_object_name]  
	,	[hierarchy_path] 
	,	[depth] 
	,	[object_class_id] 
	)
	SELECT 
		@li_instance_id_left
	,	@li_database_id_left
	,	<object_key_column_name>
	,	N''
	,	0
	,	@li_object_class_id
	FROM 
		<object_schema>.<object_table>
	WHERE 
		<object_key_column_name> = @as_object_name_left
		
	UNION ALL 

	SELECT 
		@li_instance_id_right
	,	@li_database_id_right
	,	<object_key_column_name>
	,	N''
	,	0
	,	@li_object_class_id

	
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