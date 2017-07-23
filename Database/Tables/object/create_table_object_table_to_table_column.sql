
    DROP TABLE IF EXISTS [object].[table_to_table_column]; 
    GO 

    CREATE TABLE [object].[table_to_table_column]
    (
        [object_class_id] INT NOT NULL
    ,   [subobject_class_id] INT NOT NULL
    ,   CONSTRAINT pk_table_to_table_column PRIMARY KEY
        (
            [object_class_id]
        ,   [subobject_class_id]
        )  
    );
    GO
    