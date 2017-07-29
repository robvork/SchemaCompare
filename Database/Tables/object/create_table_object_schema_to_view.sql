
    DROP TABLE IF EXISTS [object].[schema_to_view]; 
    GO 

    CREATE TABLE [object].[schema_to_view]
    (
        [object_id] INT NOT NULL
    ,   [subobject_id] INT NOT NULL
    ,   CONSTRAINT pk_schema_to_view PRIMARY KEY
        (
            [object_id]
        ,   [subobject_id]
        )  
    );
    GO
    