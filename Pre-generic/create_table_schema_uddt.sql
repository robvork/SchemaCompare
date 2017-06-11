DROP TABLE IF EXISTS [schema].[uddt];

CREATE TABLE [schema].[uddt]
(
	[database_id] INT NOT NULL
,   [schema_name] SYSNAME NOT NULL
,	[uddt_name] SYSNAME NOT NULL 
,	CONSTRAINT pk_s_uddt PRIMARY KEY([database_id], [schema_name], [uddt_name])
,	CONSTRAINT fk_s_uddt_2_ref_db FOREIGN KEY ([database_id])
		REFERENCES [instance].[database]([database_id])
		ON DELETE CASCADE
		ON UPDATE CASCADE 
);