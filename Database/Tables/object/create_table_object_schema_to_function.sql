
    DROP TABLE IF EXISTS [object].[schema_to_function]; 
    GO 

    CREATE TABLE [object].[schema_to_function]
    (
        [object_class_id] INT NOT NULL
    ,   [subobject_class_id] INT NOT NULL
    ,   CONSTRAINT pk_schema_to_function PRIMARY KEY
        (
            [object_class_id]
        ,   [subobject_class_id]
        )  
    );
    GO
    