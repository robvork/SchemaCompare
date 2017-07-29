
    DROP TABLE IF EXISTS [object].[schema_to_procedure]; 
    GO 

    CREATE TABLE [object].[schema_to_procedure]
    (
        [object_id] INT NOT NULL
    ,   [subobject_id] INT NOT NULL
    ,   CONSTRAINT pk_schema_to_procedure PRIMARY KEY
        (
            [object_id]
        ,   [subobject_id]
        )  
    );
    GO
    