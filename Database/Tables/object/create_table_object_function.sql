DROP TABLE IF EXISTS [object].[function];

CREATE TABLE [object].[function]
(
  [instance_id] INT NOT NULL
, [database_id] INT NOT NULL
, [object_id] INT NOT NULL
, [name] SYSNAME NOT NULL
, [create_date] DATETIME NOT NULL
, [is_ms_shipped] BIT NOT NULL
, [is_published] BIT NOT NULL
, [is_schema_published] BIT NOT NULL
, [modify_date] DATETIME NOT NULL
, [parent_object_id] INT NOT NULL
, [principal_id] INT NULL
, [schema_id] INT NOT NULL
, [type] CHAR(2) NULL
, [type_desc] NVARCHAR(60) NULL
);