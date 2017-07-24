
    DROP TABLE IF EXISTS [object].[database_to_schema]; 
    GO 

    CREATE TABLE [object].[database_to_schema]
    (
        [object_class_id] INT NOT NULL
    ,   [subobject_class_id] INT NOT NULL
    ,   CONSTRAINT pk_database_to_schema PRIMARY KEY
        (
            [object_class_id]
        ,   [subobject_class_id]
        )  
    );
    GO
    