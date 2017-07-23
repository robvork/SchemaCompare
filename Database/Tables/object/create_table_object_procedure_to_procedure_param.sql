
    DROP TABLE IF EXISTS [object].[procedure_to_procedure_param]; 
    GO 

    CREATE TABLE [object].[procedure_to_procedure_param]
    (
        [object_class_id] INT NOT NULL
    ,   [subobject_class_id] INT NOT NULL
    ,   CONSTRAINT pk_procedure_to_procedure_param PRIMARY KEY
        (
            [object_class_id]
        ,   [subobject_class_id]
        )  
    );
    GO
    