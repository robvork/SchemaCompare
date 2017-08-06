DROP TABLE IF EXISTS [config].[standard_metadata_key];

CREATE TABLE [config].[standard_metadata_key]
(
	[standard_metadata_key_id]   INT NOT NULL
,	[standard_metadata_key_name] SYSNAME NOT NULL
,	[standard_metadata_key_type] SYSNAME NOT NULL
,	[standard_metadata_key_precedence] INT NOT NULL
,	CONSTRAINT pk_config_standard_metadata_key
	PRIMARY KEY
	(
		standard_metadata_key_id
	)
);
