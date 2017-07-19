param
(
    $sourcePath = "C:\Users\ROBVK\Documents\Workspace\Projects\RVK.SchemaCompare\Tables\By_Schema\schema"
,   $destPath = "C:\Users\ROBVK\Documents\Workspace\Projects\RVK.SchemaCompare\Tables\By_Schema\schema"
,   $diffPath = "C:\Users\ROBVK\Documents\Workspace\Projects\RVK.SchemaCompare\Tables\By_Schema\schema\create_table_schema_diff_table.sql"
)

#Trace-Command -Name ParameterBinding -PSHost -Expression {
Get-ChildItem $sourcePath | 
Where-Object -FilterScript {$_.Name -match "create_table" -and $_.Name -notmatch "diff" } | 
Select-Object @{n="Object";
                e={$_.Name -replace "create_table_schema_(.*)\.sql", '$1'};
               } | 
Select-Object Object, 
              @{n="Name";
                e={"create_table_schema_diff_" + $_.Object + ".sql"};
               },
              @{n="Path";
                e={$destPath};
               } |
Select-Object Object,
              @{n="Path"
                e={Join-Path $_.Path $_.Name}
               } -PipelineVariable pv | 
Where-Object -FilterScript {$_.Path -ne $diffPath} |
Select-Object Path, 
              @{n="Value";e={(Get-Content $diffPath | 
                             ForEach-Object {
                                $_ -replace 
                                "\[diff_\w+\]",
                                "[diff_$($pv.Object)]"
                                            }
                             ) -join "`n"
                            }
               } |  
ForEach-Object {New-Item -Force -Path $_.Path -Value $_.Value}
#}
