DROP PROCEDURE IF EXISTS [config].[p_initialize_next_id];
GO

CREATE PROCEDURE [config].[p_initialize_next_id]
AS
BEGIN
	TRUNCATE TABLE [config].[next_id]; 

	INSERT INTO [config].[next_id]
	(
		[system_object_id]
	,	[next_id]
	)
	SELECT 
		[object_id]
	,	1
	FROM sys.tables 
END