DROP PROCEDURE IF EXISTS [config].[p_register_instance];
GO

CREATE PROCEDURE [config].[p_register_instance] 
(
	@as_instance_name SYSNAME 
)
AS
BEGIN
BEGIN TRY
	DROP TABLE IF EXISTS #instance; 

	CREATE TABLE #instance
	(
		row_num INT NOT NULL
	,	row_id INT NULL
	,	instance_name SYSNAME NOT NULL
	);

	INSERT INTO #instance
	(
		row_num
	,	instance_name
	)
	VALUES
	(
		1
	,	@as_instance_name
	);

	EXEC [config].[p_get_next_id] 
		@as_schema_name = 'config'
	,	@as_table_name = 'instance'
	,	@as_work_table_name = '#instance'
	;
END TRY
BEGIN CATCH

END CATCH;




END; 
GO