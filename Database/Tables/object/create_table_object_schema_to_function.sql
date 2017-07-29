
    DROP TABLE IF EXISTS [object].[schema_to_function]; 
    GO 

    CREATE TABLE [object].[schema_to_function]
    (
        [object_id] INT NOT NULL
    ,   [subobject_id] INT NOT NULL
    ,   CONSTRAINT pk_schema_to_function PRIMARY KEY
        (
            [object_id]
        ,   [subobject_id]
        )  
    );
    GO
    