
    DROP TABLE IF EXISTS [object].[function_to_function_param]; 
    GO 

    CREATE TABLE [object].[function_to_function_param]
    (
        [object_class_id] INT NOT NULL
    ,   [subobject_class_id] INT NOT NULL
    ,   CONSTRAINT pk_function_to_function_param PRIMARY KEY
        (
            [object_class_id]
        ,   [subobject_class_id]
        )  
    );
    GO
    