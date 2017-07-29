
    DROP TABLE IF EXISTS [object].[table_to_table_column]; 
    GO 

    CREATE TABLE [object].[table_to_table_column]
    (
        [object_id] INT NOT NULL
    ,   [subobject_id] INT NOT NULL
    ,   CONSTRAINT pk_table_to_table_column PRIMARY KEY
        (
            [object_id]
        ,   [subobject_id]
        )  
    );
    GO
    