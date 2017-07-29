
    DROP TABLE IF EXISTS [object].[view_to_view_column]; 
    GO 

    CREATE TABLE [object].[view_to_view_column]
    (
        [object_id] INT NOT NULL
    ,   [subobject_id] INT NOT NULL
    ,   CONSTRAINT pk_view_to_view_column PRIMARY KEY
        (
            [object_id]
        ,   [subobject_id]
        )  
    );
    GO
    