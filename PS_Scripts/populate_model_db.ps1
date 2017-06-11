param
(
    [String] 
    $SchemaCompareDir = "C:\Users\ROBVK\Documents\Workspace\Projects\RVK.SchemaCompare"
,
    [String]
    $ServerInstance = "ASPIRING\SQL16"
)

$Database = "model"

$CreateSchemaScripts = (
    gci $SchemaCompareDir\Schemas -Recurse create_schema*.sql | 
    select -exp fullname
    )
$CreateUDDTScripts = (
    gci $SchemaCompareDir\Types -Recurse create_type*.sql | 
    select -exp fullname
    )

$InitializeParams = @{
    ServerInstance=$ServerInstance;
    Database=$Database;
    CreateSchemaScripts=$CreateSchemaScripts;
    CreateUDDTScripts=$CreateUDDTScripts;
    CreateTableScripts=$CreateTableScripts;
    CreateForeignKeyScripts=$CreateForeignKeyScripts;
    CreateProcedureScripts=$CreateProcedureScripts;
    CreateFunctionScripts=$CreateFunctionScripts;
}
