param
(
    [String] 
    $SchemaCompareDir = "C:\Users\ROBVK\Documents\Workspace\Projects\RVK.SchemaCompare"
,
    [String]
    $ServerInstance = "ASPIRING\SQL16"
,
    [String]
    $Database = "SchemaCompare"
)


$CreateSchemaScripts = (
    gci $SchemaCompareDir\Schemas -Recurse create_schema*.sql | 
    select -exp fullname
    )
$CreateUDDTScripts = (
    gci $SchemaCompareDir\Types -Recurse create_type*.sql | 
    select -exp fullname
    )
$CreateTableScripts = (
    gci $SchemaCompareDir\Tables\By_Schema -Recurse create_table*.sql | 
    select -exp fullname
    )
$CreateForeignKeyScripts = @()
$CreateProcedureScripts = (
    gci $SchemaCompareDir\Procedures -Recurse p_*.sql | 
    select -exp fullname
    )
$CreateFunctionScripts = @(
    gci $SchemaCompareDir\SQL_functions -Recurse create_function*.sql | 
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

Initialize-SchemaCompareDB @InitializeParams -Verbose 