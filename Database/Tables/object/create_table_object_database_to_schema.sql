
    DROP TABLE IF EXISTS [object].[database_to_schema]; 
    GO 

    CREATE TABLE [object].[database_to_schema]
    (
        [object_id] INT NOT NULL
    ,   [subobject_id] INT NOT NULL
    ,   CONSTRAINT pk_database_to_schema PRIMARY KEY
        (
            [object_id]
        ,   [subobject_id]
        )  
    );
    GO
    