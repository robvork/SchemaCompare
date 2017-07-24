
    DROP TABLE IF EXISTS [object].[schema_to_procedure]; 
    GO 

    CREATE TABLE [object].[schema_to_procedure]
    (
        [object_class_id] INT NOT NULL
    ,   [subobject_class_id] INT NOT NULL
    ,   CONSTRAINT pk_schema_to_procedure PRIMARY KEY
        (
            [object_class_id]
        ,   [subobject_class_id]
        )  
    );
    GO
    