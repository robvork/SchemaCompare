param
(
    $sourcePath = "C:\Users\ROBVK\Documents\Workspace\Projects\RVK.SchemaCompare\Tables\By_Schema\schema"
,   $destPath = "C:\Users\ROBVK\Documents\Workspace\Projects\RVK.SchemaCompare\Tables\By_Schema\property"
)

Get-ChildItem $sourcePath -Filter "create_table_*.sql" | 
Select-Object name, fullname | 
ForEach-Object {Copy-Item -Path $_.FullName -Destination "$destPath\$($_.Name -replace 'schema', 'property')" -PassThru |
                % { Set-Content -Path $_.FullName -Value (Get-Content $_.FullName | ForEach-Object { $_ -replace '\[schema\]','[property]'})}
} 
