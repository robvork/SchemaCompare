
    DROP TABLE IF EXISTS [object].[procedure_to_procedure_param]; 
    GO 

    CREATE TABLE [object].[procedure_to_procedure_param]
    (
        [object_id] INT NOT NULL
    ,   [subobject_id] INT NOT NULL
    ,   CONSTRAINT pk_procedure_to_procedure_param PRIMARY KEY
        (
            [object_id]
        ,   [subobject_id]
        )  
    );
    GO
    