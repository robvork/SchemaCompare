DROP TABLE IF EXISTS [object].[function];

CREATE TABLE [object].[function]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT IDENTITY(1, 1) NOT NULL
, [name] SYSNAME NOT NULL
, [create_date] DATETIME NULL
, [is_ms_shipped] BIT NULL
, [is_published] BIT NULL
, [is_schema_published] BIT NULL
, [modify_date] DATETIME NULL
, [parent_object_id] INT NULL
, [principal_id] INT NULL
, [schema_id] INT NULL
, [type] CHAR(2) NULL
, [type_desc] NVARCHAR(60) NULL
);