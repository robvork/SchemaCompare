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

	IF @li_database_id_right IS NULL
		RAISERROR(N'Invalid right database name', 16, 1);

	DROP TABLE IF EXISTS #compare_staging;

	CREATE TABLE #compare_staging
	(
		[instance_id] INT NOT NULL
	,	[database_id] INT NOT NULL
	,	[parent_object_class_id] INT NULL
	,	[parent_object_metadata_key] INT NULL
	,	[object_class_id] INT NOT NULL
	,	[object_metadata_key] INT NOT NULL
	,	[path] NVARCHAR(MAX) NOT NULL
	,	[depth] INT NOT NULL
	,	[has_match] BIT NULL
	,	CONSTRAINT pk_compare_staging 
		PRIMARY KEY 
		(
			[instance_id]
		,	[database_id]
		,	[path]
		)
	);

	IF @ai_depth < 0 
		SET @ai_depth = (SELECT COUNT(*) FROM [config].[object_class]);

	INSERT INTO #compare_staging
	(
		[instance_id]
	,	[database_id] 
	,	[parent_object_class_id]
	,	[parent_object_metadata_key]
	,	[object_class_id]
	,	[object_metadata_key]
	,	[path] 
	,	[depth] 
	,	[has_match]
	)


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