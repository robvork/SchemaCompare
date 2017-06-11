DROP PROCEDURE IF EXISTS [config].[p_initialize_object_class_property];
GO

CREATE PROCEDURE [config].[p_initialize_object_class_property]
AS
BEGIN
	BEGIN TRY
		DECLARE @li_system_type_id_nchar INT;
		DECLARE @li_system_type_id_nvarchar INT;
		DECLARE @li_system_type_id_char INT;
		DECLARE @li_system_type_id_varchar INT;

		DROP TABLE IF EXISTS #object_class_property;

		CREATE TABLE #object_class_property
		(
			row_num INT NOT NULL PRIMARY KEY
		,	row_id INT NULL
		,	object_class_id INT NOT NULL
		,	object_class_property_system_type_id INT NOT NULL
		,	object_class_property_name NVARCHAR(128) NOT NULL
		,	object_class_property_is_nullable NVARCHAR(128) NOT NULL
		,	object_class_property_has_length BIT NOT NULL
		,	object_class_property_length INT NOT NULL
		,	object_class_property_is_enabled BIT NOT NULL DEFAULT 1
		);

		CREATE TABLE #view
		(
			[view_object_id] INT NOT NULL PRIMARY KEY
		,	[schema_name] SYSNAME NOT NULL
		,	[view_name] SYSNAME NOT NULL
		);

		CREATE TABLE #view_property
		(
			view_object_id INT NOT NULL PRIMARY KEY
		,	view_property_system_type_id INT NOT NULL
		,	view_property_name NVARCHAR(128) NOT NULL
		,	view_property_is_nullable NVARCHAR(128) NOT NULL
		,	view_property_has_length BIT NOT NULL
		,	view_property_length INT NOT NULL
		);
		/*
			sys.tables
			sys.views
			sys.columns
			sys.procedures
			sys.objects
			sys.parameters
		*/

		SET @li_system_type_id_nchar = 
		(
			SELECT [system_type_id]
			FROM sys.types 
			WHERE [name] = 'NCHAR'
		);
		SET @li_system_type_id_nvarchar = 
		(
			SELECT [system_type_id]
			FROM sys.types 
			WHERE [name] = 'NVARCHAR'
		);
		SET @li_system_type_id_char = 
		(
			SELECT [system_type_id]
			FROM sys.types 
			WHERE [name] = 'CHAR'
		);
		SET @li_system_type_id_varchar = 
		(
			SELECT [system_type_id]
			FROM sys.types 
			WHERE [name] = 'VARCHAR'
		);
		
		WITH views_to_insert AS
		(
			SELECT [schema_name], [view_name] 
			FROM 
			(
				VALUES 
				('sys', 'tables')
			,	('sys', 'views')
			,	('sys', 'procedures')
			,	('sys', 'columns')
			,	('sys', 'parameters')
			,	('sys', 'types')
			) AS view_names_values ([schema_name], [view_name])
		)
		INSERT INTO #view
		(
			[view_object_id]
		,	[schema_name]
		,	[view_name]
		)
		SELECT 
			V.[object_id] 
		,	VI.[schema_name] 
		,	VI.[view_name] 
		FROM views_to_insert AS VI 
			 INNER JOIN sys.all_views AS V
				ON VI.[view_name] = V.[name]
		; 

		INSERT INTO #view_property
		(
			[view_object_id]
		,	[view_property_name]
		,	[view_property_system_type_id]
		,	[view_property_is_nullable]
		,	[view_property_has_length]
		,	[view_property_length]
		)






	END TRY
	BEGIN CATCH
	END CATCH;
END;