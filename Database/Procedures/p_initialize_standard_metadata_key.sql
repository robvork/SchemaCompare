DROP PROCEDURE IF EXISTS [config].[p_initialize_standard_metadata_key];
GO

CREATE PROCEDURE [config].[p_initialize_standard_metadata_key]
(
	@ai_debug_level INT = 0
,	@as_input_table_name SYSNAME
)
AS
BEGIN
	DECLARE @ls_sql NVARCHAR(MAX); 

	DROP TABLE IF EXISTS #standard_metadata_key;

	CREATE TABLE #standard_metadata_key
	(
		[standard_metadata_key_id] INT NOT NULL PRIMARY KEY
	,	[standard_metadata_key_name] SYSNAME NOT NULL
	,	[standard_metadata_key_type] SYSNAME NOT NULL
	);

	/*******************************************************************************
	Extract data from object class input table into local table, prepare for id assignment
	*******************************************************************************/

	SET @ls_sql = CONCAT 
	(
		N'
		INSERT INTO #standard_metadata_key 
		(
			[standard_metadata_key_id]
		,	[standard_metadata_key_name]
		,	[standard_metadata_key_type]
		)
		SELECT 
			ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		,	[standard_metadata_key_name]
		,	[standard_metadata_key_type]
		FROM ', @as_input_table_name, N' AS I
		;'
	);
	
	IF @ai_debug_level > 0
		PRINT CONCAT(N'Executing the following in DSQL: ', @ls_sql);
	
	EXEC(@ls_sql);
	
	IF @ai_debug_level > 1
	BEGIN
		SELECT N'#standard_metadata_key';
		SELECT * FROM #standard_metadata_key;
	END;
	
	/*******************************************************************************
	Create new rows in [config].[object_class] using #standard_metadata_key
	*******************************************************************************/
	INSERT INTO 
		[config].[standard_metadata_key]
	(
		[standard_metadata_key_id]   
	,	[standard_metadata_key_name] 
	,	[standard_metadata_key_type] 
	)
	SELECT 
		[standard_metadata_key_id]   
	,	[standard_metadata_key_name] 
	,	[standard_metadata_key_type] 
	FROM 
		#standard_metadata_key
	;

	IF @ai_debug_level > 1
	BEGIN
		SELECT '[config].[standard_metadata_key] at the end of procedure';
		SELECT * FROM [config].[standard_metadata_key];
	END;
END; 