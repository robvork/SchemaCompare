/*
We want to see the differences in the data model between two databases,
possibly on different SQL Server instances. (Let's focus on the one SQL Server instance case for now)
*/

/*
	Differences in schema:
		Object level differences
		[
			object x exists in one db but not the other
				where x in (UDDT, table, procedure, view, function)
		]

		Detail level differences
		[
			general: same name but different details

			UDDT : same type name, different definition

			table : same table name, different columns

			procedure : same procedure name, different parameters or definition

			view : same view name, different set of columns 
				(similar to table, since views are just virtual tables)

			functions : same procedure name, different parameters or definition
		]
*/

/*
	So to begin, let's just focus on object level differences, as this should
	be easier to perform. We just have to look at names and do some simple
	EXCEPT SQL logic
*/

USE master; 

IF EXISTS(SELECT * FROM sys.databases WHERE [name] = 'SchemaCompare')
	DROP DATABASE SchemaCompare; 

CREATE DATABASE SchemaCompare; 
GO

USE SchemaCompare;
GO

-- What databases are we comparing?
DROP TABLE IF EXISTS dbo.[database];

CREATE TABLE dbo.[database]
(
	[database_id] INT NOT NULL 
,	[database_name] SYSNAME NOT NULL
,	CONSTRAINT pk_ref_db PRIMARY KEY([database_id])
);

-- What are the names of the schemas in each database?
-- The 'o_' prefix is prepended to tables which support object level comparisons

DROP TABLE IF EXISTS dbo.[o_schema];

CREATE TABLE dbo.o_schema
(
	[database_id] INT NOT NULL
,	[schema_name] SYSNAME NOT NULL
,	CONSTRAINT pk_o_schema PRIMARY KEY([database_id], [schema_name])
,	CONSTRAINT fk_o_schema_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES dbo.[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
)

-- What are the names of the tables within each database schema?
-- The 'o_' prefix is prepended to tables which support object level comparisons
DROP TABLE IF EXISTS dbo.[o_table];

CREATE TABLE dbo.o_table
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[table_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_o_table PRIMARY KEY([database_id], [table_name])
,	CONSTRAINT fk_o_table_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES dbo.[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);

-- What are the names of the user-defined data types within each database schema?
-- The 'o_' prefix is prepended to tables which support object level comparisons
DROP TABLE IF EXISTS dbo.[o_uddt];

CREATE TABLE dbo.o_uddt
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[uddt_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_o_uddt PRIMARY KEY([database_id], [uddt_name])
,	CONSTRAINT fk_o_uddt_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES dbo.[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);

-- What are the names of the procedures within each database schema?
-- The 'o_' prefix is prepended to tables which support object level comparisons
DROP TABLE IF EXISTS dbo.[o_proc];

CREATE TABLE dbo.o_proc
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[proc_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_o_proc PRIMARY KEY([database_id], [proc_name])
,	CONSTRAINT fk_o_proc_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES dbo.[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);

-- What are the names of the functions within each database schema?
-- The 'o_' prefix is prepended to tables which support object level comparisons
DROP TABLE IF EXISTS dbo.[o_func];

CREATE TABLE dbo.o_func
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[func_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_o_func PRIMARY KEY([database_id], [func_name])
,	CONSTRAINT fk_o_func_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES dbo.[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);

-- What are the names of the views within each database schema?
-- The 'o_' prefix is prepended to tables which support object level comparisons
DROP TABLE IF EXISTS dbo.[o_view];

CREATE TABLE dbo.o_view
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[view_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_o_view PRIMARY KEY([database_id], [view_name])
,	CONSTRAINT fk_o_view_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES dbo.[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);

-- Given a two database ids database_id_left and database_id_right,
-- list the table_names which appear only on the left or the right.
-- Which of the two is indicated by database_id_indicator
DROP TABLE IF EXISTS dbo.[d_table];

CREATE TABLE dbo.d_table
(
	[database_id_left] INT NOT NULL
,	[database_id_right] INT NOT NULL
,	[database_id_indicator] INT NOT NULL
,	[schema_name] SYSNAME NOT NULL
,	[table_name] SYSNAME NOT NULL
,	CONSTRAINT pk_d_table PRIMARY KEY
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator] 
	,	[schema_name] 
	,	[table_name]
	)

,	CONSTRAINT fk_d_table_left_2_db 
	FOREIGN KEY ([database_id_left])
		REFERENCES dbo.[database]([database_id])

,	CONSTRAINT fk_d_table_right_2_db 
	FOREIGN KEY ([database_id_right])
		REFERENCES dbo.[database]([database_id])

,   CONSTRAINT chk_d_table_indicator_is_left_or_right
	CHECK (
		   [database_id_indicator] = [database_id_left]
			OR
		   [database_id_indicator] = [database_id_right]
		  )
);

DROP TABLE IF EXISTS dbo.[d_view];

CREATE TABLE dbo.d_view
(
	[database_id_left] INT NOT NULL
,	[database_id_right] INT NOT NULL
,	[database_id_indicator] INT NOT NULL
,	[schema_name] SYSNAME NOT NULL
,	[view_name] SYSNAME NOT NULL

,	CONSTRAINT pk_d_view PRIMARY KEY
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator] 
	,	[schema_name]
	,	[view_name]
	)

,	CONSTRAINT fk_d_view_left_2_db 
	FOREIGN KEY ([database_id_left])
		REFERENCES dbo.[database]([database_id])

,	CONSTRAINT fk_d_view_right_2_db 
	FOREIGN KEY ([database_id_right])
		REFERENCES dbo.[database]([database_id])

,   CONSTRAINT chk_d_view_indicator_is_left_or_right
	CHECK (
		   [database_id_indicator] = [database_id_left]
			OR
		   [database_id_indicator] = [database_id_right]
		  )
);

DROP TABLE IF EXISTS dbo.[d_uddt];

CREATE TABLE dbo.d_uddt
(
	[database_id_left] INT NOT NULL
,	[database_id_right] INT NOT NULL
,	[database_id_indicator] INT NOT NULL
,	[schema_name] SYSNAME NOT NULL
,	[uddt_name] SYSNAME NOT NULL

,	CONSTRAINT pk_d_uddt PRIMARY KEY
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name] 
	,	[uddt_name]
	)

,	CONSTRAINT fk_d_uddt_left_2_db 
	FOREIGN KEY ([database_id_left])
		REFERENCES dbo.[database]([database_id])

,	CONSTRAINT fk_d_uddt_right_2_db 
	FOREIGN KEY ([database_id_right])
		REFERENCES dbo.[database]([database_id])

,   CONSTRAINT chk_d_uddt_indicator_is_left_or_right
	CHECK (
		   [database_id_indicator] = [database_id_left]
			OR
		   [database_id_indicator] = [database_id_right]
		  )
);

DROP TABLE IF EXISTS dbo.[d_proc];

CREATE TABLE dbo.d_proc
(
	[database_id_left] INT NOT NULL
,	[database_id_right] INT NOT NULL
,	[database_id_indicator] INT NOT NULL
,	[schema_name] SYSNAME NOT NULL
,	[proc_name] SYSNAME NOT NULL

,	CONSTRAINT pk_d_proc PRIMARY KEY
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name] 
	,	[proc_name]
	)

,	CONSTRAINT fk_d_proc_left_2_db 
	FOREIGN KEY ([database_id_left])
		REFERENCES dbo.[database]([database_id])

,	CONSTRAINT fk_d_proc_right_2_db 
	FOREIGN KEY ([database_id_right])
		REFERENCES dbo.[database]([database_id])

,   CONSTRAINT chk_d_proc_indicator_is_left_or_right
	CHECK (
		   [database_id_indicator] = [database_id_left]
			OR
		   [database_id_indicator] = [database_id_right]
		  )
);

DROP TABLE IF EXISTS dbo.[d_func];

CREATE TABLE dbo.d_func
(
	[database_id_left] INT NOT NULL
,	[database_id_right] INT NOT NULL
,	[database_id_indicator] INT NOT NULL
,	[schema_name] SYSNAME NOT NULL
,	[func_name] SYSNAME NOT NULL
,	CONSTRAINT pk_d_func PRIMARY KEY
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator] 
	,	[schema_name]
	,	[func_name]
	)

,	CONSTRAINT fk_d_func_left_2_db 
	FOREIGN KEY ([database_id_left])
		REFERENCES dbo.[database]([database_id])

,	CONSTRAINT fk_d_func_right_2_db 
	FOREIGN KEY ([database_id_right])
		REFERENCES dbo.[database]([database_id])

,   CONSTRAINT chk_d_func_indicator_is_left_or_right
	CHECK (
		   [database_id_indicator] = [database_id_left]
			OR
		   [database_id_indicator] = [database_id_right]
		  )
);



/*
	Object level
*/

/*
SELECT [schema_id], [name]
FROM sys.types 
WHERE is_user_defined = 1

SELECT [schema_id], [name] 
FROM sys.tables

SELECT [schema_id], [name] 
FROM sys.procedures

SELECT [schema_id], [name] 
FROM sys.objects
WHERE [type] = 'FN'

SELECT [schema_id], [name] 
FROM sys.views 
--*/

INSERT INTO dbo.[database]
VALUES (1, 'd1')
,	   (2, 'd2')
; 

INSERT INTO dbo.o_schema 
VALUES 
-- only in d1
	   (1, 's_d1')
-- common to d1 and d2
,	   (1, 's1')
,	   (1, 's2')
,	   (2, 's1')
,	   (2, 's2')
-- only in d2
,	   (2, 's_d2')
;

INSERT INTO dbo.o_table
VALUES 
	-- only in d1's s1
	(1, 's1', 's1_ta')

	-- common to d1's and d2's s1
,	(1, 's1', 's1_tb')
,	(2, 's1', 's1_tb')

	-- only in d2's s1
,	(2, 's1', 's1_tc')

	-- only in d1's s2
,	(1, 's2', 's2_tw')
,	(1, 's2', 's2_tx')

	-- common to d1's and d2's s2
,	(1, 's2', 's2_ty')
,	(2, 's2', 's2_ty')

	-- only in d2's s2
,	(2, 's2', 's2_tz')
;

INSERT INTO dbo.o_view
VALUES 
	-- only in d1's s1
	(1, 's1', 's1_va')

	-- common to d1's and d2's s1
,	(1, 's1', 's1_vb')
,	(2, 's1', 's1_vb')

	-- only in d2's s1
,	(2, 's1', 's1_vc')

	-- only in d1's s2
,	(1, 's2', 's2_vw')
,	(1, 's2', 's2_vx')

	-- common to d1's and d2's s2
,	(1, 's2', 's2_vy')
,	(2, 's2', 's2_vy')

	-- only in d2's s2
,	(2, 's2', 's2_vz')
;

INSERT INTO dbo.o_uddt
VALUES 
	-- only in d1's s1
	(1, 's1', 's1_uddta')

	-- common to d1's and d2's s1
,	(1, 's1', 's1_uddtb')
,	(2, 's1', 's1_uddtb')

	-- only in d2's s1
,	(2, 's1', 's1_uddtc')

	-- only in d1's s2
,	(1, 's2', 's2_uddtw')
,	(1, 's2', 's2_uddtx')

	-- common to d1's and d2's s2
,	(1, 's2', 's2_uddty')
,	(2, 's2', 's2_uddty')

	-- only in d2's s2
,	(2, 's2', 's2_uddtz')
;

INSERT INTO dbo.o_func
VALUES 
	-- only in d1's s1
	(1, 's1', 's1_funca')

	-- common to d1's and d2's s1
,	(1, 's1', 's1_funcb')
,	(2, 's1', 's1_funcb')

	-- only in d2's s1
,	(2, 's1', 's1_funcc')

	-- only in d1's s2
,	(1, 's2', 's2_funcw')
,	(1, 's2', 's2_funcx')

	-- common to d1's and d2's s2
,	(1, 's2', 's2_funcy')
,	(2, 's2', 's2_funcy')

	-- only in d2's s2
,	(2, 's2', 's2_funcz')
;

INSERT INTO dbo.o_proc 
VALUES 
	-- only in d1's s1
	(1, 's1', 's1_proca')

	-- common to d1's and d2's s1
,	(1, 's1', 's1_procb')
,	(2, 's1', 's1_procb')

	-- only in d2's s1
,	(2, 's1', 's1_procc')

	-- only in d1's s2
,	(1, 's2', 's2_procw')
,	(1, 's2', 's2_procx')

	-- common to d1's and d2's s2
,	(1, 's2', 's2_procy')
,	(2, 's2', 's2_procy')

	-- only in d2's s2
,	(2, 's2', 's2_procz')
;

SELECT 'database';
SELECT * FROM dbo.[database] 

SELECT 'o_schema';
SELECT * FROM dbo.[o_schema] ORDER BY [schema_name], [database_id]

SELECT 'o_table';
SELECT * FROM dbo.[o_table] ORDER BY [schema_name], [database_id]

SELECT 'o_func';
SELECT * FROM dbo.[o_func] ORDER BY [schema_name], [database_id]

SELECT 'o_view';
SELECT * FROM dbo.[o_view] ORDER BY [schema_name], [database_id]

SELECT 'o_proc';
SELECT * FROM dbo.[o_proc] ORDER BY [schema_name], [database_id]

SELECT 'o_uddt';
SELECT * FROM dbo.[o_uddt] ORDER BY [schema_name], [database_id]

DROP PROCEDURE IF EXISTS dbo.p_compare_object; 
GO

CREATE PROCEDURE dbo.p_compare_object 
(
	@li_database_id_left INT
,	@li_database_id_right INT
)
AS
BEGIN
	SET NOCOUNT ON; 
	
	WITH tables_only_on_left AS
	(
		SELECT 
			   [schema_name] 
		,	   [table_name] 
		FROM dbo.o_table
		WHERE [database_id] = @li_database_id_left

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [table_name] 
		FROM dbo.o_table
		WHERE [database_id] = @li_database_id_right
	)
	INSERT INTO dbo.d_table 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[table_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_left
	,	   [schema_name]
	,	   [table_name] 
	FROM tables_only_on_left
	;

	WITH tables_only_on_right AS
	(
		SELECT 
			   [schema_name] 
		,	   [table_name] 
		FROM dbo.o_table
		WHERE [database_id] = @li_database_id_right

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [table_name] 
		FROM dbo.o_table
		WHERE [database_id] = @li_database_id_left
	)
	INSERT INTO dbo.d_table 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[table_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_right
	,	   [schema_name]
	,	   [table_name] 
	FROM tables_only_on_right
	;
	
	WITH views_only_on_left AS
	(
		SELECT 
			   [schema_name] 
		,	   [view_name] 
		FROM dbo.o_view
		WHERE [database_id] = @li_database_id_left

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [view_name] 
		FROM dbo.o_view
		WHERE [database_id] = @li_database_id_right
	)
	INSERT INTO dbo.d_view 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[view_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_left
	,	   [schema_name]
	,	   [view_name] 
	FROM views_only_on_left
	;

	WITH views_only_on_right AS
	(
		SELECT 
			   [schema_name] 
		,	   [view_name] 
		FROM dbo.o_view
		WHERE [database_id] = @li_database_id_right

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [view_name] 
		FROM dbo.o_view
		WHERE [database_id] = @li_database_id_left
	)
	INSERT INTO dbo.d_view 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[view_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_right
	,	   [schema_name]
	,	   [view_name] 
	FROM views_only_on_right
	;

	WITH uddts_only_on_left AS
	(
		SELECT 
			   [schema_name] 
		,	   [uddt_name] 
		FROM dbo.o_uddt
		WHERE [database_id] = @li_database_id_left

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [uddt_name] 
		FROM dbo.o_uddt
		WHERE [database_id] = @li_database_id_right
	)
	INSERT INTO dbo.d_uddt 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[uddt_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_left
	,	   [schema_name]
	,	   [uddt_name] 
	FROM uddts_only_on_left
	;

	WITH uddts_only_on_right AS
	(
		SELECT 
			   [schema_name] 
		,	   [uddt_name] 
		FROM dbo.o_uddt
		WHERE [database_id] = @li_database_id_right

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [uddt_name] 
		FROM dbo.o_uddt
		WHERE [database_id] = @li_database_id_left
	)
	INSERT INTO dbo.d_uddt 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[uddt_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_right
	,	   [schema_name]
	,	   [uddt_name] 
	FROM uddts_only_on_right
	;

	WITH procs_only_on_left AS
	(
		SELECT 
			   [schema_name] 
		,	   [proc_name] 
		FROM dbo.o_proc
		WHERE [database_id] = @li_database_id_left

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [proc_name] 
		FROM dbo.o_proc
		WHERE [database_id] = @li_database_id_right
	)
	INSERT INTO dbo.d_proc 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[proc_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_left
	,	   [schema_name]
	,	   [proc_name] 
	FROM procs_only_on_left
	;

	WITH procs_only_on_right AS
	(
		SELECT 
			   [schema_name] 
		,	   [proc_name] 
		FROM dbo.o_proc
		WHERE [database_id] = @li_database_id_right

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [proc_name] 
		FROM dbo.o_proc
		WHERE [database_id] = @li_database_id_left
	)
	INSERT INTO dbo.d_proc 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[proc_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_right
	,	   [schema_name]
	,	   [proc_name] 
	FROM procs_only_on_right
	;

	WITH funcs_only_on_left AS
	(
		SELECT 
			   [schema_name] 
		,	   [func_name] 
		FROM dbo.o_func
		WHERE [database_id] = @li_database_id_left

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [func_name] 
		FROM dbo.o_func
		WHERE [database_id] = @li_database_id_right
	)
	INSERT INTO dbo.d_func 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[func_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_left
	,	   [schema_name]
	,	   [func_name] 
	FROM funcs_only_on_left
	;

	WITH funcs_only_on_right AS
	(
		SELECT 
			   [schema_name] 
		,	   [func_name] 
		FROM dbo.o_func
		WHERE [database_id] = @li_database_id_right

		EXCEPT

		SELECT 
			   [schema_name] 
		,	   [func_name] 
		FROM dbo.o_func
		WHERE [database_id] = @li_database_id_left
	)
	INSERT INTO dbo.d_func 
	(
		[database_id_left]
	,	[database_id_right]
	,	[database_id_indicator]
	,	[schema_name]
	,	[func_name]
	)
	SELECT @li_database_id_left
	,	   @li_database_id_right
	,	   @li_database_id_right
	,	   [schema_name]
	,	   [func_name] 
	FROM funcs_only_on_right
	;
END;
GO

EXEC dbo.p_compare_object @li_database_id_left = 1 
,						  @li_database_id_right = 2
;

SELECT * FROM dbo.d_table ORDER BY [database_id_indicator], [schema_name], [table_name]
SELECT * FROM dbo.d_view ORDER BY [database_id_indicator], [schema_name], [view_name]
SELECT * FROM dbo.d_uddt ORDER BY [database_id_indicator], [schema_name], [uddt_name]
SELECT * FROM dbo.d_proc ORDER BY [database_id_indicator], [schema_name], [proc_name]
SELECT * FROM dbo.d_func ORDER BY [database_id_indicator], [schema_name], [func_name]

